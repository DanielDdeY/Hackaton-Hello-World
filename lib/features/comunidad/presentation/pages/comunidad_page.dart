import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/mocks/mock_comunidad_repository.dart';
import '../../domain/repositories/comunidad_repository.dart';
import '../controllers/comunidad_controller.dart';
import '../tabs/eventos_tab.dart';
import '../tabs/favores_tab.dart';
import '../tabs/hoy_tab.dart';
import '../tabs/vecinos_tab.dart';

/// Pantalla principal del Módulo de Comunidad con 4 pestañas superiores.
class ComunidadPage extends StatelessWidget {
  const ComunidadPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Conecta con el repositorio inyectado o usa Mock por defecto para pruebas
    final repository = Provider.of<ComunidadRepository?>(context) ?? MockComunidadRepository();

    return ChangeNotifierProvider(
      create: (_) => ComunidadController(repository: repository),
      child: const _ComunidadVista(),
    );
  }
}

class _ComunidadVista extends StatefulWidget {
  const _ComunidadVista();

  @override
  State<_ComunidadVista> createState() => _ComunidadVistaState();
}

class _ComunidadVistaState extends State<_ComunidadVista> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _irATab(int index) {
    if (_tabController.index != index) {
      _tabController.animateTo(index);
    }
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
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Hoy'),
            Tab(text: 'Favores'),
            Tab(text: 'Eventos'),
            Tab(text: 'Vecinos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          HoyTab(
            onIrAFavores: () => _irATab(1),
            onIrAEventos: () => _irATab(2),
          ),
          const FavoresTab(),
          const EventosTab(),
          const VecinosTab(),
        ],
      ),
    );
  }
}

