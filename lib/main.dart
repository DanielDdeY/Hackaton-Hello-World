import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'core/firebase/configure_firebase_emulators.dart';
import 'core/theme/app_theme.dart';
import 'features/ayuda_prevencion/ayuda_prevencion_page.dart';
import 'features/create_post/data/mocks/mock_location_provider.dart';
import 'features/create_post/data/mocks/mock_photo_picker.dart';
import 'features/create_post/data/services/device_location_provider.dart';
import 'features/create_post/data/services/firebase_auth_gateway.dart';
import 'features/create_post/data/services/geocoding_address_resolver.dart';
import 'features/create_post/data/services/image_picker_photo_picker.dart';
import 'features/create_post/domain/services/auth_gateway.dart';
import 'features/create_post/domain/services/location_provider.dart';
import 'features/create_post/domain/services/photo_picker.dart';
import 'features/create_post/presentation/pages/category_selector_page.dart';
import 'home/home.dart';

import 'firebase_options.dart';
import 'screens/map/data/map_location_provider.dart'
    show GeolocatorLocationProvider;
import 'screens/map/map_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseApp = await initializeVeciAppFirebase(
    DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MyApp(
      authGateway: FirebaseAuthGateway(
        FirebaseAuth.instanceFor(app: firebaseApp),
      ),
      locationProvider: DeviceLocationProvider(
        mapProvider: GeolocatorLocationProvider(),
        addressResolver: const GeocodingAddressResolver(),
      ),
      photoPicker: ImagePickerPhotoPicker(ImagePicker()),
    ),
  );
}

const _text = Color(0xFF1A1A1A);
const _navigationLabel = TextStyle(
  color: _text,
  fontSize: 11,
  fontWeight: FontWeight.w500,
);

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    this.locationProvider = const MockLocationProvider(),
    this.photoPicker = const MockPhotoPicker(),
    this.authGateway,
  });

  final LocationProvider locationProvider;
  final PhotoPicker photoPicker;
  final AuthGateway? authGateway;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthGateway?>.value(value: authGateway),
        Provider<LocationProvider>.value(value: locationProvider),
        Provider<PhotoPicker>.value(value: photoPicker),
      ],
      child: MaterialApp(
        title: 'VeciApp',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('es', 'PE')],
        theme: createAppTheme(),
        home: const _AppGate(),
        routes: {'/map': (_) => const MapScreen()},
      ),
    );
  }
}

class _AppGate extends StatefulWidget {
  const _AppGate();

  @override
  State<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<_AppGate> {
  bool _authenticated = false;

  @override
  Widget build(BuildContext context) {
    if (!_authenticated) {
      return MiBarrioHome(
        onAuthenticated: () => setState(() => _authenticated = true),
      );
    }
    return const _NeighborhoodShell();
  }
}

enum _Destination {
  home('Inicio', Icons.home_outlined, Icons.home, 'Resumen de tu barrio'),
  map('Mapa', Icons.map_outlined, Icons.map, 'Explora tu zona'),
  community(
    'Comunidad',
    Icons.groups_outlined,
    Icons.groups,
    'Conecta con tus vecinos',
  ),
  help(
    'Ayuda',
    Icons.help_outline,
    Icons.help,
    'Encuentra orientación y apoyo',
  );

  const _Destination(
    this.label,
    this.icon,
    this.selectedIcon,
    this.description,
  );

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String description;
}

class _NeighborhoodShell extends StatefulWidget {
  const _NeighborhoodShell();

  @override
  State<_NeighborhoodShell> createState() => _NeighborhoodShellState();
}

class _NeighborhoodShellState extends State<_NeighborhoodShell> {
  _Destination _selected = _Destination.home;
  bool _mapVisited = false;

  void _openCategorySelector() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const CategorySelectorPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // En la pestaña Mapa se oculta el AppBar del shell: la pantalla de mapa
    // trae el suyo (con la acción para ver la lista de sitios).
    return Scaffold(
      appBar: _selected == _Destination.map
          ? null
          : AppBar(
              title: Text(_selected.label, style: theme.textTheme.titleLarge),
            ),
      // IndexedStack conserva el estado del mapa (cámara, filtros, búsqueda)
      // al cambiar de pestaña y volver a Mapa.
      body: IndexedStack(
        index: _selected.index,
        children: [
          const MiBarrioHome(homeOnly: true),
          _mapVisited
              ? const MapScreen()
              : _PlaceholderPage(description: _Destination.map.description),
          _PlaceholderPage(description: _Destination.community.description),
          const AyudaPrevencionPage(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: _openCategorySelector,
        tooltip: 'Publicar',
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        padding: EdgeInsets.zero,
        height: 48 + 2.4 * MediaQuery.textScalerOf(context).scale(11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _navigationItem(_Destination.home),
            _navigationItem(_Destination.map),
            const SizedBox(
              width: 68,
              child: Padding(
                padding: EdgeInsets.only(top: 38),
                child: ExcludeSemantics(
                  child: Text(
                    'Publicar',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _navigationLabel,
                  ),
                ),
              ),
            ),
            _navigationItem(_Destination.community),
            _navigationItem(_Destination.help),
          ],
        ),
      ),
    );
  }

  Widget _navigationItem(_Destination destination) {
    final selected = _selected == destination;
    final colors = Theme.of(context).colorScheme;
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          onTap: () => setState(() {
            _selected = destination;
            if (destination == _Destination.map) {
              _mapVisited = true;
            }
          }),
          child: Padding(
            padding: const EdgeInsets.only(top: 10, left: 2, right: 2),
            child: Column(
              children: [
                Icon(
                  selected ? destination.selectedIcon : destination.icon,
                  color: selected ? colors.primary : colors.onSurfaceVariant,
                ),
                const SizedBox(height: 4),
                Text(
                  destination.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: _navigationLabel,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}
