import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'data/map_places_repository.dart';
import 'models/map_place.dart';
import 'widgets/place_details_sheet.dart';
import 'widgets/places_list_sheet.dart';

/// Pantalla de mapa con los negocios y los sitios guardados por los usuarios.
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
  const MapScreen({super.key, this.repository});

  /// Fuente de datos. Si es `null` se usan los datos de ejemplo.
  final MapPlacesRepository? repository;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

enum _PlaceFilter { all, businesses, saved }

class _MapScreenState extends State<MapScreen> {
  static const LatLng _initialTarget = LatLng(40.4168, -3.7038);
  static const double _initialZoom = 13.5;

  late final MapPlacesRepository _repository;
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription<List<MapPlace>>? _subscription;
  GoogleMapController? _mapController;

  List<MapPlace> _places = const [];
  bool _loading = true;
  Object? _error;
  String _query = '';
  _PlaceFilter _filter = _PlaceFilter.all;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? MockMapPlacesRepository();
    _subscribe();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
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

  List<MapPlace> get _visiblePlaces {
    final query = _query.trim().toLowerCase();
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
          return matchesFilter && matchesQuery;
        })
        .toList(growable: false);
  }

  Set<Marker> _markersFor(List<MapPlace> places) {
    return {
      for (final place in places)
        Marker(
          markerId: MarkerId(place.id),
          position: place.location,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            place.isBusiness
                ? BitmapDescriptor.hueOrange
                : BitmapDescriptor.hueAzure,
          ),
          onTap: () => _showDetails(place),
        ),
    };
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
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(place.location, 16),
    );
  }

  void _recenter() {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_initialTarget, _initialZoom),
    );
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa'),
        actions: [
          IconButton(
            onPressed: _loading || _error != null
                ? null
                : () => _openList(visiblePlaces),
            icon: const Icon(Icons.format_list_bulleted_rounded),
            tooltip: 'Ver lista de sitios',
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _initialTarget,
              zoom: _initialZoom,
            ),
            onMapCreated: (controller) => _mapController = controller,
            markers: _markersFor(visiblePlaces),
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onTap: (_) => FocusScope.of(context).unfocus(),
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
                  Text('Cargando sitios…', style: theme.textTheme.bodyMedium),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _recenter,
        tooltip: 'Centrar mapa',
        child: const Icon(Icons.my_location_rounded),
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
