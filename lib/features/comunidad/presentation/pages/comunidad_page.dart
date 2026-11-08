import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../data/mocks/mock_comunidad_feed_repository.dart';
import '../../data/mocks/mock_comunidad_repository.dart';
import '../../domain/repositories/comunidad_feed_repository.dart';
import '../../domain/repositories/comunidad_repository.dart';
import '../../../community/presentation/community_sos_section.dart';
import '../controllers/comunidad_controller.dart';
import '../tabs/eventos_tab.dart';
import '../tabs/favores_tab.dart';
import '../tabs/servicios_tab.dart';
import '../tabs/vecinos_tab.dart';

/// Pantalla principal del Módulo de Comunidad con 4 pestañas superiores.
class ComunidadPage extends StatelessWidget {
  const ComunidadPage({super.key, this.onOpenMap});

  final void Function(LatLng? location)? onOpenMap;

  static final _mockFeed = MockComunidadFeedRepository();

  @override
  Widget build(BuildContext context) {
    // Conecta con el repositorio inyectado o usa Mock por defecto para pruebas
    final repository =
        Provider.of<ComunidadRepository?>(context) ?? MockComunidadRepository();
    final feed = context.watch<ComunidadFeedRepository?>() ?? _mockFeed;

    return ChangeNotifierProvider(
      create: (_) => ComunidadController(repository: repository),
      child: _ComunidadVista(feed: feed, onOpenMap: onOpenMap),
    );
  }
}

class _ComunidadVista extends StatefulWidget {
  const _ComunidadVista({required this.feed, this.onOpenMap});

  final ComunidadFeedRepository feed;
  final void Function(LatLng? location)? onOpenMap;

  @override
  State<_ComunidadVista> createState() => _ComunidadVistaState();
}

class _ComunidadVistaState extends State<_ComunidadVista>
    with SingleTickerProviderStateMixin {
  static const _tabs = [
    Tab(text: 'Favores'),
    Tab(text: 'Servicios'),
    Tab(text: 'Eventos'),
    Tab(text: 'Vecinos'),
  ];

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comunidad'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          indicatorColor: theme.colorScheme.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          tabs: _tabs,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: CommunitySosSection(onOpenMap: widget.onOpenMap),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                FavoresTab(repository: widget.feed),
                ServiciosTab(repository: widget.feed),
                EventosTab(repository: widget.feed),
                const VecinosTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
