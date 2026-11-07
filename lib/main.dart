import 'package:flutter/material.dart';

import 'screens/map/map_screen.dart';

void main() {
  runApp(const MyApp());
}

//colorcitos//
const _background = Color(0xFFFAFAFA);
const _surface = Color(0xFFFFFFFF);
const _primary = Color(0xFF006D77);
const _text = Color(0xFF1A1A1A);
const _secondaryText = Color(0xFF5C5C5C);
const _navigationLabel = TextStyle(
  color: _text,
  fontSize: 11,
  fontWeight: FontWeight.w500,
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seguridad Vecinal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: _background,
        colorScheme: const ColorScheme.light(
          primary: _primary,
          surface: _surface,
          onSurface: _text,
          onSurfaceVariant: _secondaryText,
        ),
        appBarTheme: const AppBarThemeData(backgroundColor: _background),
      ),
      home: const _NeighborhoodShell(),
      routes: {'/map': (_) => const MapScreen()},
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
  const _NeighborhoodShell();

  @override
  State<_NeighborhoodShell> createState() => _NeighborhoodShellState();
}

class _NeighborhoodShellState extends State<_NeighborhoodShell> {
  _Destination _selected = _Destination.home;

  Future<void> _showPublishOptions() async {
    final option = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _surface,
      barrierLabel: 'Cerrar opciones de publicación',
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const _PublishSheet(),
    );
    if (!mounted || option == null) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Elegiste: $option')));
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge
        ?.copyWith(fontWeight: FontWeight.w600);

    // En la pestaña Mapa se oculta el AppBar del shell: la pantalla de mapa
    // trae el suyo (con la acción para ver la lista de sitios).
    return Scaffold(
      appBar: _selected == _Destination.map
          ? null
          : AppBar(title: Text(_selected.label, style: titleStyle)),
      // IndexedStack conserva el estado del mapa (cámara, filtros, búsqueda)
      // al cambiar de pestaña y volver a Mapa.
      body: IndexedStack(
        index: _selected.index,
        children: [
          _PlaceholderPage(description: _Destination.home.description),
          const MapScreen(),
          _PlaceholderPage(description: _Destination.community.description),
          _PlaceholderPage(description: _Destination.help.description),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: _showPublishOptions,
        tooltip: 'Publicar',
        backgroundColor: _primary,
        foregroundColor: _surface,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
      ),
      bottomNavigationBar: BottomAppBar(
        color: _surface,
        surfaceTintColor: Colors.transparent,
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
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          onTap: () => setState(() => _selected = destination),
          child: Padding(
            padding: const EdgeInsets.only(top: 10, left: 2, right: 2),
            child: Column(
              children: [
                Icon(
                  selected ? destination.selectedIcon : destination.icon,
                  color: selected ? _primary : _secondaryText,
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

class _PublishSheet extends StatelessWidget {
  const _PublishSheet();

  static const _options = [
    ('Pedir ayuda', Icons.front_hand_outlined),
    ('Ofrecer un favor', Icons.volunteer_activism_outlined),
    ('Compartir un aviso', Icons.campaign_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Publicación rápida',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            for (final (label, icon) in _options)
              ListTile(
                leading: Icon(icon, color: _primary),
                title: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () => Navigator.pop(context, label),
              ),
          ],
        ),
      ),
    );
  }
}
