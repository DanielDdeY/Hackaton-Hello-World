import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../features/emergency/domain/emergency_type_labels.dart';
import '../../features/emergency/presentation/emergency_type_icons.dart';
import 'data/map_location_provider.dart';
import 'data/map_places_repository.dart';
import 'data/map_focus_controller.dart';
import 'data/emergency_map_repository.dart';
import 'models/map_place.dart';
import 'utils/map_geo.dart';
import 'widgets/location_permission_view.dart';
import 'widgets/map_legend.dart';
import 'widgets/place_details_sheet.dart';
import 'widgets/places_list_sheet.dart';

/// Pantalla de mapa con los negocios y los sitios guardados por los usuarios.
///
/// Solo muestra el mapa dentro de un radio de [kMapRadiusMeters] desde la
/// ubicación del usuario: la cámara no puede salirse del círculo, el límite
/// se dibuja en el mapa y los sitios fuera de él se ocultan. Si el usuario
/// no concede su ubicación, la pantalla queda bloqueada con una vista para
/// activar el GPS o conceder el permiso.
///
/// Los datos se obtienen de un [MapPlacesRepository]. De momento se usa
/// [MockMapPlacesRepository]; cuando esté lista la conexión con Firebase basta
/// con inyectar una implementación que escuche Firestore:
///
/// ```dart
/// MapScreen(repository: FirebaseMapPlacesRepository())
/// ```
///
/// Para previsualizar la pantalla antes de enlazarla en `main.dart`, usa:
/// `home: const MapScreen()`.
class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    this.repository,
    this.locationProvider,
    this.emergencyRepository,
    this.focusController,
  });

  /// Fuente de datos. Si es `null` se usan los datos de ejemplo.
  final MapPlacesRepository? repository;

  /// Fuente de la ubicación del usuario. Si es `null` se usa
  /// [GeolocatorLocationProvider].
  final MapLocationProvider? locationProvider;
  final EmergencyMapRepository? emergencyRepository;

  /// Permite centrar la cámara en una alerta SOS concreta.
  final MapFocusController? focusController;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

enum _PlaceFilter { all, businesses, saved }

class _MapScreenState extends State<MapScreen> {
  static const double _initialZoom = 14;

  late final MapPlacesRepository _repository;
  late final MapLocationProvider _locationProvider;
  late final EmergencyMapRepository _emergencyRepository;
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription<List<MapPlace>>? _subscription;
  StreamSubscription<List<EmergencyMapAlert>>? _emergencySubscription;
  StreamSubscription<LocationResult>? _locationSubscription;
  final MapController _mapController = MapController();

  /// Ubicación del usuario; hasta que no está disponible no se muestra el mapa.
  LatLng? _userLocation;

  /// `true` si se está usando la última posición conocida (GPS apagado).
  bool _isLastKnown = false;
  LocationFailure? _locationFailure;
  bool _locationLoading = true;

  List<MapPlace> _places = const [];
  List<EmergencyMapAlert> _emergencyAlerts = const [];
  bool _loading = true;
  Object? _error;
  Object? _emergencyError;
  String _query = '';
  _PlaceFilter _filter = _PlaceFilter.all;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? MockMapPlacesRepository();
    _locationProvider = widget.locationProvider ?? GeolocatorLocationProvider();
    _emergencyRepository =
        widget.emergencyRepository ?? const EmptyEmergencyMapRepository();
    _subscribe();
    _subscribeEmergencyAlerts();
    _resolveLocation();
    widget.focusController?.addListener(_applyFocusRequest);
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyFocusRequest());
  }

  @override
  void dispose() {
    widget.focusController?.removeListener(_applyFocusRequest);
    _subscription?.cancel();
    _emergencySubscription?.cancel();
    _locationSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _applyFocusRequest() {
    final target = widget.focusController?.target;
    if (target == null) return;
    try {
      _mapController.move(target, _initialZoom + 1);
    } catch (_) {
      // El mapa todavía no está listo; se reintenta con la próxima solicitud.
    }
  }

  void _subscribeEmergencyAlerts() {
    _emergencySubscription?.cancel();
    _emergencySubscription = _emergencyRepository.watchAlerts().listen(
      (alerts) {
        if (!mounted) return;
        setState(() {
          _emergencyAlerts = alerts
              .where((alert) => alert.status == 'active')
              .toList(growable: false);
          _emergencyError = null;
        });
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() => _emergencyError = error);
      },
    );
  }

  void _subscribe() {
    _subscription?.cancel();
    _subscription = _repository.watchPlaces().listen(
      (places) {
        if (!mounted) return;
        setState(() {
          _places = places;
          _loading = false;
          _error = null;
        });
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _error = error;
          _loading = false;
        });
      },
    );
  }

  void _retry() {
    setState(() {
      _loading = true;
      _error = null;
    });
    _subscribe();
  }

  /// Pide la ubicación del usuario. Mientras no haya ninguna posición
  /// (ni en vivo ni guardada), el mapa permanece bloqueado en la vista de
  /// permisos; si ya hay posición y el reintento falla, el mapa sigue
  /// visible con el último punto conocido.
  Future<void> _resolveLocation() async {
    if (_userLocation == null) {
      setState(() {
        _locationLoading = true;
        _locationFailure = null;
      });
    }
    final result = await _locationProvider.currentLocation();
    if (!mounted) return;
    if (result.location != null) {
      setState(() {
        _locationLoading = false;
        _userLocation = result.location;
        _isLastKnown = result.isLastKnown;
        _locationFailure = null;
      });
      _watchLocation();
      WidgetsBinding.instance.addPostFrameCallback((_) => _applyFocusRequest());
    } else {
      setState(() {
        _locationLoading = false;
        if (_userLocation == null) {
          _locationFailure = result.failure ?? LocationFailure.error;
        }
      });
    }
  }

  /// Sigue las posiciones del usuario: actualiza el marcador, el círculo de
  /// 1.8 km y el aviso de "última ubicación conocida" sin bloquear el mapa.
  void _watchLocation() {
    _locationSubscription?.cancel();
    _locationSubscription = _locationProvider.watch().listen(
      (update) {
        if (!mounted || update.location == null) return;
        setState(() {
          _userLocation = update.location;
          _isLastKnown = update.isLastKnown;
        });
        _keepCameraInside();
      },
      onError: (_) {
        // El stream falló: el mapa se queda en el último punto conocido.
      },
    );
  }

  /// Si el usuario se movió más allá de 1.8 km del centro de la cámara, se
  /// recentra para no quedar fuera del área permitida.
  void _keepCameraInside() {
    final userLocation = _userLocation;
    if (userLocation == null) return;
    try {
      if (distanceMeters(userLocation, _mapController.camera.center) >
          kMapRadiusMeters) {
        _mapController.move(userLocation, _initialZoom);
      }
    } catch (_) {
      // El mapa aún no está renderizado; se aplica en el próximo movimiento.
    }
  }

  /// Acción del botón de la vista bloqueada según el motivo del fallo.
  Future<void> _handleLocationAction() async {
    try {
      switch (_locationFailure) {
        case LocationFailure.permissionDeniedForever:
          await Geolocator.openAppSettings();
        case LocationFailure.serviceDisabled:
          await Geolocator.openLocationSettings();
        default:
          break;
      }
    } catch (_) {
      // El sistema no abrió ajustes; reintentamos igualmente abajo.
    }
    await _resolveLocation();
  }

  List<MapPlace> get _visiblePlaces {
    final query = _query.trim().toLowerCase();
    final userLocation = _userLocation;
    return _places
        .where((place) {
          final matchesFilter = switch (_filter) {
            _PlaceFilter.all => true,
            _PlaceFilter.businesses => place.kind == PlaceKind.business,
            _PlaceFilter.saved => place.kind == PlaceKind.userSaved,
          };
          final matchesQuery =
              query.isEmpty ||
              place.name.toLowerCase().contains(query) ||
              place.category.toLowerCase().contains(query) ||
              place.address.toLowerCase().contains(query);
          // Solo los sitios dentro del radio de 1.8 km del usuario.
          final withinRadius =
              userLocation == null ||
              isWithinRadius(userLocation, place.location);
          return matchesFilter && matchesQuery && withinRadius;
        })
        .toList(growable: false);
  }

  List<Marker> _markersFor(
    List<MapPlace> places,
    List<EmergencyMapAlert> alerts,
  ) {
    return [
      for (final place in places)
        Marker(
          point: place.location,
          width: 36,
          height: 36,
          child: GestureDetector(
            onTap: () => _showDetails(place),
            child: Icon(
              place.isBusiness
                  ? Icons.storefront_rounded
                  : Icons.bookmark_rounded,
              size: 32,
              color: place.isBusiness
                  ? Colors.orange.shade700
                  : Colors.blue.shade700,
              shadows: const [Shadow(color: Colors.black45, blurRadius: 6)],
            ),
          ),
        ),
      for (final alert in alerts)
        Marker(
          point: alert.location,
          width: 44,
          height: 44,
          child: Semantics(
            button: true,
            label:
                '${emergencyTypeLabel(alert.type)}: ${alert.title}. '
                'Ver detalle',
            child: GestureDetector(
              onTap: () => _showEmergencyDetails(alert),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xffb71c1c),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black38, blurRadius: 5),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(
                  emergencyTypeIcon(alert.type),
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),
        ),
      if (_userLocation != null) _userMarker(_userLocation!),
    ];
  }

  Future<void> _showEmergencyDetails(EmergencyMapAlert alert) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          emergencyTypeIcon(alert.type),
          color: const Color(0xffb71c1c),
          size: 32,
        ),
        title: Text(alert.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emergencyTypeLabel(alert.type)),
            if (alert.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(alert.description),
            ] else ...[
              const SizedBox(height: 8),
              const Text('El vecino está completando los detalles del SOS.'),
            ],
            const SizedBox(height: 8),
            const Text(
              'Alerta activa · radio de 200 m',
              style: TextStyle(
                color: Color(0xffb71c1c),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  /// Punto azul con halo que indica la posición del usuario.
  Marker _userMarker(LatLng location) {
    return Marker(
      point: location,
      width: 28,
      height: 28,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.25),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        alignment: Alignment.center,
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.blue.shade700,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Future<void> _showDetails(MapPlace place) {
    return showPlaceDetailsSheet(
      context,
      place: place,
      onFocus: () => _focusOn(place),
    );
  }

  Future<void> _openList(List<MapPlace> places) {
    if (places.isEmpty) return Future<void>.value();
    return showPlacesListSheet(
      context,
      places: places,
      onPlaceSelected: (place) {
        _focusOn(place);
        _showDetails(place);
      },
    );
  }

  void _focusOn(MapPlace place) {
    final userLocation = _userLocation;
    final target = userLocation == null
        ? place.location
        : clampToRadius(userLocation, place.location);
    _mapController.move(target, 16);
  }

  void _recenter() {
    final userLocation = _userLocation;
    if (userLocation == null) {
      _resolveLocation();
      return;
    }
    _mapController.move(userLocation, _initialZoom);
  }

  void _selectFilter(_PlaceFilter filter) {
    setState(() => _filter = filter);
    FocusScope.of(context).unfocus();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final visiblePlaces = _visiblePlaces;
    final theme = Theme.of(context);
    final locationReady = _userLocation != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa'),
        actions: [
          IconButton(
            onPressed: _loading || _error != null || !locationReady
                ? null
                : () => _openList(visiblePlaces),
            icon: const Icon(Icons.format_list_bulleted_rounded),
            tooltip: 'Ver lista de sitios',
          ),
        ],
      ),
      body: _buildBody(theme, visiblePlaces),
      floatingActionButton: locationReady
          ? FloatingActionButton(
              onPressed: _recenter,
              tooltip: 'Centrar en mi ubicación',
              child: const Icon(Icons.my_location_rounded),
            )
          : null,
    );
  }

  /// Hasta que no hay ubicación el mapa no se muestra: primero el estado de
  /// carga y después la vista que bloquea el mapa hasta conceder el permiso.
  Widget _buildBody(ThemeData theme, List<MapPlace> visiblePlaces) {
    if (_locationLoading) {
      return const _OverlayCard(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(width: 16),
            Flexible(
              child: Text(
                'Obteniendo tu ubicación…',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    final failure = _locationFailure;
    if (failure != null) {
      return LocationPermissionView(
        failure: failure,
        onAction: _handleLocationAction,
      );
    }

    return _buildMap(theme, visiblePlaces);
  }

  Widget _buildMap(ThemeData theme, List<MapPlace> visiblePlaces) {
    final userLocation = _userLocation!;
    final alertTypes = [for (final alert in _emergencyAlerts) alert.type];
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: userLocation,
            initialZoom: _initialZoom,
            // Evita alejarse tanto que el viewport supere el diámetro del círculo.
            minZoom: 13.5,
            // El centro de la cámara no puede salirse de los 1.8 km.
            cameraConstraint: RadiusCameraConstraint(center: userLocation),
            // Igual que antes con Google Maps: sin rotación.
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
            onTap: (_, _) => FocusScope.of(context).unfocus(),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.hackaton_hello_world',
              maxZoom: 19,
            ),
            // Límite visible de los 1.8 km alrededor del usuario.
            CircleLayer(
              circles: [
                CircleMarker(
                  point: userLocation,
                  radius: kMapRadiusMeters,
                  useRadiusInMeter: true,
                  color: theme.colorScheme.primary.withValues(alpha: 0.06),
                  borderColor: theme.colorScheme.primary.withValues(
                    alpha: 0.45,
                  ),
                  borderStrokeWidth: 2,
                ),
                for (final alert in _emergencyAlerts)
                  CircleMarker(
                    point: alert.location,
                    radius: alert.radiusMeters,
                    useRadiusInMeter: true,
                    color: const Color(0xffb71c1c).withValues(alpha: 0.13),
                    borderColor: const Color(0xffb71c1c),
                    borderStrokeWidth: 2.5,
                  ),
              ],
            ),
            MarkerLayer(markers: _markersFor(visiblePlaces, _emergencyAlerts)),
            RichAttributionWidget(
              attributions: [
                const TextSourceAttribution('OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSearchField(theme),
                const SizedBox(height: 10),
                _buildFilters(theme),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: MapLegend(alertTypes: alertTypes),
                ),
                if (_emergencyError != null) ...[
                  const SizedBox(height: 8),
                  Material(
                    color: const Color(0xfffff1f0),
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Text(
                        'No se pudieron cargar las alertas SOS cercanas.',
                        style: TextStyle(color: Color(0xffb71c1c)),
                      ),
                    ),
                  ),
                ],
                if (_isLastKnown) ...[
                  const SizedBox(height: 10),
                  _buildLastKnownBanner(theme),
                ],
              ],
            ),
          ),
        ),
        if (_loading)
          _OverlayCard(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Text(
                    'Cargando sitios…',
                    style: theme.textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        if (_error != null)
          _OverlayCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off_rounded,
                  size: 36,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 12),
                const Text(
                  'No se pudieron cargar los sitios.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        if (!_loading && _error == null && visiblePlaces.isEmpty)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: _EmptyResults(onClear: _clearSearch),
          ),
      ],
    );
  }

  /// Aviso discreto de que el mapa usa la última posición conocida en vez
  /// de la actual. Tocarlo vuelve a pedir la ubicación.
  Widget _buildLastKnownBanner(ThemeData theme) {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(16),
      color: theme.colorScheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _resolveLocation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(
                Icons.location_off_rounded,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Mostrando tu última ubicación conocida',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.refresh_rounded,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(16),
      color: theme.colorScheme.surface,
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onChanged: (value) => setState(() => _query = value),
        decoration: InputDecoration(
          hintText: 'Buscar negocios o sitios guardados',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  onPressed: _clearSearch,
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Borrar búsqueda',
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFilters(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            theme,
            label: 'Todos',
            icon: Icons.layers_rounded,
            filter: _PlaceFilter.all,
          ),
          _buildFilterChip(
            theme,
            label: 'Negocios',
            icon: Icons.storefront_rounded,
            filter: _PlaceFilter.businesses,
          ),
          _buildFilterChip(
            theme,
            label: 'Guardados',
            icon: Icons.bookmark_rounded,
            filter: _PlaceFilter.saved,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    ThemeData theme, {
    required String label,
    required IconData icon,
    required _PlaceFilter filter,
  }) {
    final selected = _filter == filter;
    final selectedColor = filter == _PlaceFilter.saved
        ? theme.colorScheme.tertiary
        : theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) => _selectFilter(filter),
        avatar: Icon(
          icon,
          size: 18,
          color: selected
              ? theme.colorScheme.onSecondaryContainer
              : selectedColor,
        ),
        label: Text(label),
        selectedColor: selectedColor.withValues(alpha: 0.2),
        backgroundColor: theme.colorScheme.surface,
        side: BorderSide(
          color: selected
              ? selectedColor.withValues(alpha: 0.5)
              : theme.colorScheme.outlineVariant,
        ),
        labelStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _OverlayCard extends StatelessWidget {
  const _OverlayCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: child,
        ),
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            Icon(
              Icons.search_off_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('No hay sitios que coincidan con la búsqueda.'),
            ),
            TextButton(onPressed: onClear, child: const Text('Limpiar')),
          ],
        ),
      ),
    );
  }
}
