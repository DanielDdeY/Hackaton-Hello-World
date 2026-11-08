import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'core/firebase/configure_firebase_emulators.dart';
import 'core/theme/app_theme.dart';
import 'features/ayuda_prevencion/ayuda_prevencion_page.dart';
import 'features/comunidad/data/mocks/mock_comunidad_repository.dart';
import 'features/comunidad/data/mocks/mock_comunidad_feed_repository.dart';
import 'features/comunidad/data/repositories/firestore_comunidad_feed_repository.dart';
import 'features/comunidad/data/repositories/firestore_comunidad_repository.dart';
import 'features/comunidad/domain/repositories/comunidad_feed_repository.dart';
import 'features/comunidad/domain/repositories/comunidad_repository.dart';
import 'features/comunidad/presentation/pages/comunidad_page.dart';
import 'features/create_post/data/mocks/mock_location_provider.dart';
import 'features/create_post/data/mocks/mock_photo_picker.dart';
import 'features/create_post/data/repositories/firestore_post_repository.dart';
import 'features/create_post/data/repositories/post_document_store.dart';
import 'features/create_post/data/services/device_location_provider.dart';
import 'features/create_post/data/services/firebase_auth_gateway.dart';
import 'features/create_post/data/services/firebase_photo_storage.dart';
import 'features/create_post/data/services/firebase_storage_image_uploader.dart';
import 'features/create_post/data/services/geocoding_address_resolver.dart';
import 'features/create_post/data/services/image_picker_photo_picker.dart';
import 'features/create_post/data/services/keyword_service_category_classifier.dart';
import 'features/create_post/data/services/profile_post_author_name_resolver.dart';
import 'features/create_post/domain/services/auth_gateway.dart';
import 'features/create_post/domain/services/location_provider.dart';
import 'features/create_post/domain/services/photo_picker.dart';
import 'features/create_post/domain/services/post_repository.dart';
import 'features/create_post/domain/services/service_category_classifier.dart';
import 'features/create_post/presentation/pages/category_selector_page.dart';
import 'firebase_options.dart';
import 'home/home.dart';
import 'home/user_profile.dart';
import 'screens/map/data/map_location_provider.dart'
    show GeolocatorLocationProvider;
import 'screens/map/data/firebase_emergency_map_repository.dart';
import 'screens/map/data/map_focus_controller.dart';
import 'screens/map/map_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseApp = await initializeVeciAppFirebase(
    DefaultFirebaseOptions.currentPlatform,
  );
  final auth = FirebaseAuthGateway(FirebaseAuth.instanceFor(app: firebaseApp));
  final firestore = FirebaseFirestore.instanceFor(app: firebaseApp);
  final profileStore = FirestoreUserProfileStore(firestore);
  final comunidadRepository = FirestoreComunidadRepository(
    firestore: firestore,
    auth: FirebaseAuth.instanceFor(app: firebaseApp),
    distritoPorDefecto: 'Ate',
  );
  unawaited(
    comunidadRepository.sembrarDatosSimulados().catchError((error) {
      debugPrint('Sembrado de datos simulados diferido: $error');
    }),
  );

  runApp(
    MyApp(
      authGateway: auth,
      comunidadRepository: comunidadRepository,
      comunidadFeedRepository: FirestoreComunidadFeedRepository(
        firestore: firestore,
        auth: auth,
      ),
      profileStore: profileStore,
      postRepository: FirestorePostRepository(
        authorNameResolver: ProfilePostAuthorNameResolver(profileStore),
        documents: FirebasePostDocumentStore(firestore),
        uploader: FirebaseStorageImageUploader(
          FirebasePhotoStorage(FirebaseStorage.instanceFor(app: firebaseApp)),
        ),
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
  MyApp({
    super.key,
    this.locationProvider = const MockLocationProvider(),
    this.photoPicker = const MockPhotoPicker(),
    this.authGateway,
    this.profileStore,
    this.postRepository,
    ComunidadRepository? comunidadRepository,
    ComunidadFeedRepository? comunidadFeedRepository,
    ServiceCategoryClassifier? serviceCategoryClassifier,
  }) : comunidadRepository = comunidadRepository ?? MockComunidadRepository(),
       comunidadFeedRepository =
           comunidadFeedRepository ?? MockComunidadFeedRepository(),
       serviceCategoryClassifier =
           serviceCategoryClassifier ?? KeywordServiceCategoryClassifier();

  final LocationProvider locationProvider;
  final PhotoPicker photoPicker;
  final AuthGateway? authGateway;
  final UserProfileStore? profileStore;
  final PostRepository? postRepository;
  final ComunidadRepository comunidadRepository;
  final ComunidadFeedRepository comunidadFeedRepository;
  final ServiceCategoryClassifier serviceCategoryClassifier;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthGateway?>.value(value: authGateway),
        Provider<UserProfileStore?>.value(value: profileStore),
        Provider<PostRepository?>.value(value: postRepository),
        Provider<LocationProvider>.value(value: locationProvider),
        Provider<PhotoPicker>.value(value: photoPicker),
        Provider<ComunidadRepository>.value(value: comunidadRepository),
        Provider<ComunidadFeedRepository>.value(value: comunidadFeedRepository),
        Provider<ServiceCategoryClassifier>.value(
          value: serviceCategoryClassifier,
        ),
      ],
      child: MaterialApp(
        title: 'VeciApp',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('es', 'PE')],
        theme: createAppTheme(),
        home: const _AppGate(),
        routes: {
          '/map': (_) => MapScreen(
            emergencyRepository: FirebaseEmergencyMapRepository(
              firestore: FirebaseFirestore.instance,
              auth: FirebaseAuth.instance,
            ),
          ),
        },
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
    return _NeighborhoodShell(
      onSignedOut: () {
        setState(() => _authenticated = false);
      },
    );
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
  const _NeighborhoodShell({this.onSignedOut});

  final VoidCallback? onSignedOut;

  @override
  State<_NeighborhoodShell> createState() => _NeighborhoodShellState();
}

class _NeighborhoodShellState extends State<_NeighborhoodShell> {
  final _mapFocusController = MapFocusController();
  _Destination _selected = _Destination.home;
  bool _mapVisited = false;

  @override
  void dispose() {
    _mapFocusController.dispose();
    super.dispose();
  }

  void _openMap([LatLng? location]) {
    if (location != null) _mapFocusController.focus(location);
    setState(() {
      _mapVisited = true;
      _selected = _Destination.map;
    });
  }

  void _openCategorySelector() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const CategorySelectorPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Mapa y Comunidad gestionan sus propios AppBars superiores
    final ocultarAppBar =
        _selected == _Destination.map || _selected == _Destination.community;

    return Scaffold(
      appBar: ocultarAppBar
          ? null
          : AppBar(
              title: Text(_selected.label, style: theme.textTheme.titleLarge),
            ),
      // IndexedStack conserva el estado de mapa y pestañas de comunidad
      body: IndexedStack(
        index: _selected.index,
        children: [
          MiBarrioHome(
            homeOnly: true,
            onSignedOut: widget.onSignedOut,
            onOpenMap: _openMap,
          ),
          _mapVisited
              ? MapScreen(
                  emergencyRepository: FirebaseEmergencyMapRepository(
                    firestore: FirebaseFirestore.instance,
                    auth: FirebaseAuth.instance,
                  ),
                  focusController: _mapFocusController,
                )
              : _PlaceholderPage(description: _Destination.map.description),
          ComunidadPage(onOpenMap: _openMap),

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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 38),
                child: ExcludeSemantics(
                  child: Text(
                    'Publicar',
                    textAlign: TextAlign.center,
                    maxLines: 1,
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
