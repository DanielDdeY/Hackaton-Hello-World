import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../create_post/domain/services/auth_gateway.dart';
import '../../../economy/data/demo_ranking_seeder.dart';
import '../../../economy/domain/models/app_user.dart';
import '../../../economy/domain/repositories/user_repository.dart';
import '../../../economy/domain/services/period_provider.dart';
import '../../domain/entities/vecino_ranking.dart';
import '../controllers/comunidad_controller.dart';
import '../pages/vecino_detalle_page.dart';
import '../widgets/reconocimiento_dialog.dart';

class VecinosTab extends StatefulWidget {
  const VecinosTab({super.key});

  @override
  State<VecinosTab> createState() => _VecinosTabState();
}

class _VecinosTabState extends State<VecinosTab> {
  int _reloadToken = 0;
  (UserRepository?, String, String, int)? _query;
  Stream<List<AppUser>>? _leaderboard;

  void _reintentar(ComunidadController controller) {
    setState(() => _reloadToken++);
    controller.cargarRanking();
  }

  Future<void> _abrirHerramientasDemo(
      BuildContext context, {
        required String district,
        required ComunidadController controller,
      }) async {
    if (!kEnableDemoTools) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => _DemoRankingToolsSheet(
        district: district,
        onChanged: () {
          if (mounted) _reintentar(controller);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ComunidadController>();
    final userRepository = context.watch<UserRepository?>();
    final simulatablePeriod = context.watch<SimulatablePeriodProvider?>();
    final activePeriod =
        simulatablePeriod?.currentPeriod ??
            context.watch<PeriodProvider?>()?.currentPeriod ??
            '';
    final currentUid = context.watch<AuthGateway?>()?.currentUid;
    final distrito = controller.distritoRanking.trim().isEmpty
        ? 'Ate'
        : controller.distritoRanking.trim();
    if (userRepository != null && !controller.distritoResuelto) {
      return controller.error == null
          ? const Center(child: CircularProgressIndicator())
          : _EstadoErrorRanking(onReintentar: () => _reintentar(controller));
    }
    final query = (userRepository, distrito, activePeriod, _reloadToken);
    if (_query != query) {
      _query = query;
      _leaderboard = userRepository?.watchMonthlyLeaderboard(district: distrito);
    }
    return StreamBuilder<List<AppUser>>(
      key: ValueKey(query),
      stream: _leaderboard,
      builder: (context, snapshot) => _buildRanking(
        context,
        controller: controller,
        distrito: distrito,
        currentUid: currentUid,
        monthlySnapshot: userRepository == null ? null : snapshot,
      ),
    );
  }

  Widget _buildRanking(
    BuildContext context, {
    required ComunidadController controller,
    required String distrito,
    required String? currentUid,
    required AsyncSnapshot<List<AppUser>>? monthlySnapshot,
  }) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () async => _reintentar(controller),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          TopThreeMonthlyCard(
            district: distrito,
            monthlySnapshot: monthlySnapshot,
            currentUid: currentUid,
            fallbackRanking: controller.ranking,
            onRetry: () => _reintentar(controller),
            onOpenDemoTools: kEnableDemoTools
                ? () => _abrirHerramientasDemo(
              context,
              district: distrito,
              controller: controller,
            )
                : null,
            onNominar: (vecino) => mostrarDialogoReconocimiento(
              context,
              controller,
              destinoUid: vecino.uid,
              destinoNombre: vecino.nombre,
            ),
          ),
          const SizedBox(height: 16),

          // Cabecera del ranking del barrio (filtrado por distrito)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tabla de Vecinos del Barrio',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Chip(
                      avatar: const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Color(0xFF006D77),
                      ),
                      label: Text('Barrio · $distrito'),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: const Color(0xFFE0F2F1),
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      labelPadding: const EdgeInsets.only(right: 4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (monthlySnapshot case final snapshot?)
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (snapshot.hasError)
              _EstadoErrorRanking(onReintentar: () => _reintentar(controller))
            else if (snapshot.data?.isNotEmpty != true)
              _EstadoVacioRanking(onReintentar: () => _reintentar(controller))
            else
              ..._mapUsersToRanking(
                snapshot.data!,
                currentUid: currentUid,
                fallbackDistrito: distrito,
              ).map((vecino) => _FilaVecinoRanking(vecino: vecino))
          else if (controller.cargando && controller.ranking.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (controller.error != null && controller.ranking.isEmpty)
              _EstadoErrorRanking(onReintentar: () => _reintentar(controller))
            else if (controller.ranking.isEmpty)
                _EstadoVacioRanking(onReintentar: () => _reintentar(controller))
              else
                ...controller.ranking.map((v) => _FilaVecinoRanking(vecino: v)),

          const SizedBox(height: 16),
          GestureDetector(
            onLongPress: kEnableDemoTools
                ? () => _abrirHerramientasDemo(
              context,
              district: distrito,
              controller: controller,
            )
                : null,
            child: Card(
              color: const Color(0xFFF1F8F8),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Color(0xFF006D77),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'El ranking del barrio se actualiza mensualmente según los puntos XP ganados por participar y ayudar. Se reinicia cada mes.',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<VecinoRanking> _mapUsersToRanking(
    List<AppUser> users, {
      required String? currentUid,
      required String fallbackDistrito,
    }) {
  return List<VecinoRanking>.generate(users.length, (index) {
    final user = users[index];
    return VecinoRanking(
      uid: user.uid,
      nombre: user.name,
      iniciales: _inicialesDe(user.name),
      distrito: user.district.trim().isNotEmpty
          ? user.district
          : fallbackDistrito,
      xpPeriodo: user.effectiveMonthlyXp,
      posicion: index + 1,
      nivel: user.level,
      esUsuarioActual: currentUid != null && user.uid == currentUid,
      estrellas: user.averageStars.round(),
      xpTotal: user.xpTotal,
    );
  }, growable: false);
}

String _inicialesDe(String nombre) {
  final partes = nombre
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .take(2)
      .map((p) => p.substring(0, 1).toUpperCase())
      .join();
  return partes.isEmpty ? 'V' : partes;
}

class TopThreeMonthlyCard extends StatelessWidget {
  const TopThreeMonthlyCard({
    super.key,
    required this.district,
    this.currentUid,
    this.monthlySnapshot,
    this.fallbackRanking = const [],
    this.onRetry,
    this.onOpenDemoTools,
    this.onNominar,
  });

  final String district;
  final String? currentUid;
  final AsyncSnapshot<List<AppUser>>? monthlySnapshot;
  final List<VecinoRanking> fallbackRanking;
  final VoidCallback? onRetry;
  final VoidCallback? onOpenDemoTools;
  final ValueChanged<VecinoRanking>? onNominar;

  @override
  Widget build(BuildContext context) {
    final userRepository = context.watch<UserRepository?>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.secondary, width: 1.5),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [
              colors.surface,
              colors.secondaryContainer.withValues(alpha: 0.35),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: monthlySnapshot != null
            ? _buildMonthlySnapshot(context, monthlySnapshot!)
            : userRepository != null
            ? StreamBuilder<List<AppUser>>(
                stream: userRepository.watchTopThreeOfMonth(district: district),
                builder: _buildMonthlySnapshot,
              )
            : _buildTopThreeContent(
                context,
                fallbackRanking
                    .where((v) => v.xpPeriodo > 0)
                    .take(3)
                    .toList(growable: false),
              ),
      ),
    );
  }

  Widget _buildMonthlySnapshot(
    BuildContext context,
    AsyncSnapshot<List<AppUser>> snapshot,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting &&
        !snapshot.hasData) {
      return _buildHeaderAndBody(
        context,
        body: const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
        ),
      );
    }
    if (snapshot.hasError) {
      return _buildHeaderAndBody(
        context,
        body: _TopThreeErrorBody(onRetry: onRetry),
      );
    }
    final topUsers = _mapUsersToRanking(
      (snapshot.data ?? const <AppUser>[]).take(3).toList(growable: false),
      currentUid: currentUid,
      fallbackDistrito: district,
    );
    return _buildTopThreeContent(context, topUsers);
  }

  Widget _buildTopThreeContent(
      BuildContext context,
      List<VecinoRanking> topThree,
      ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    if (topThree.isEmpty) {
      return _buildHeaderAndBody(
        context,
        body: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colors.secondary.withValues(alpha: 0.45),
            ),
          ),
          child: Text(
            'Aún no hay puntos este mes en el barrio. Participa ayudando a tus vecinos para inaugurar el podio.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return _buildHeaderAndBody(
      context,
      first: topThree.first,
      body: Column(
        children: [
          for (var i = 0; i < topThree.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _FilaPodioMes(vecino: topThree[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderAndBody(
      BuildContext context, {
        required Widget body,
        VecinoRanking? first,
      }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.secondary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.workspace_premium,
                color: colors.onSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top 3 del Mes del Barrio',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                  Text(
                    'Vecinos más solidarios del barrio',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                  Text(
                    'Barrio · $district',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        body,
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            GestureDetector(
              onLongPress: kEnableDemoTools ? onOpenDemoTools : null,
              child: Text(
                'Se reinicia cada mes',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            if (first != null && onNominar != null)
              OutlinedButton.icon(
                onPressed: () => onNominar!(first),
                icon: const Icon(Icons.thumb_up_alt_outlined, size: 16),
                label: const Text('Reconocer a un vecino'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.primary,
                  side: BorderSide(color: colors.secondary),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _DemoRankingToolsSheet extends StatefulWidget {
  const _DemoRankingToolsSheet({
    required this.district,
    required this.onChanged,
  });

  final String district;
  final VoidCallback onChanged;

  @override
  State<_DemoRankingToolsSheet> createState() => _DemoRankingToolsSheetState();
}

class _DemoRankingToolsSheetState extends State<_DemoRankingToolsSheet> {
  bool _busy = false;
  String? _feedback;

  Future<void> _seedDemoUsers() async {
    final seeder = context.read<DemoRankingSeeder?>();
    if (seeder == null || _busy) return;
    setState(() {
      _busy = true;
      _feedback = null;
    });
    try {
      final count = await seeder.seed(district: widget.district);
      widget.onChanged();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _feedback =
        'Se cargaron $count vecinos de demostración en el barrio (${widget.district}).';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _feedback = 'No se pudieron cargar los datos de demostración: $error';
      });
    }
  }

  Future<void> _clearDemoUsers() async {
    final seeder = context.read<DemoRankingSeeder?>();
    if (seeder == null || _busy) return;
    setState(() {
      _busy = true;
      _feedback = null;
    });
    try {
      final count = await seeder.clear();
      widget.onChanged();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _feedback =
        'Se eliminaron $count vecinos de demostración (isDemo: true).';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _feedback = 'No se pudieron borrar los datos de demostración: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final simulator = context.watch<SimulatablePeriodProvider?>();
    final seeder = context.watch<DemoRankingSeeder?>();
    final isSimulating = simulator?.isSimulating ?? false;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Text(
              'Herramientas de demostración (Ranking Mensual)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              simulator == null
                  ? 'Periodo activo del sistema.'
                  : isSimulating
                  ? 'Simulando nuevo mes (${simulator.currentPeriod} · solo lectura). El ranking del barrio y el XP mensual aparecen en 0 sin tocar xpTotal, Nivel ni Monedas.'
                  : 'Periodo actual en Lima: ${simulator.realPeriod}.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            if (simulator != null)
              FilledButton.icon(
                onPressed: _busy
                    ? null
                    : () {
                  simulator.toggleNextMonthSimulation();
                  widget.onChanged();
                },
                icon: Icon(
                  isSimulating ? Icons.restore : Icons.calendar_month_outlined,
                ),
                label: Text(
                  isSimulating
                      ? 'Volver al mes actual (${simulator.realPeriod})'
                      : 'Simular Nuevo Mes (${nextMonthPeriod(simulator.realPeriod)})',
                ),
              ),
            if (seeder != null)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _seedDemoUsers,
                    icon: const Icon(Icons.group_add_outlined, size: 18),
                    label: Text('Cargar vecinos demo (${widget.district})'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _clearDemoUsers,
                    icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                    label: const Text('Borrar vecinos demo'),
                  ),
                ],
              ),
            if (_feedback != null)
              Text(
                _feedback!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilaPodioMes extends StatelessWidget {
  const _FilaPodioMes({required this.vecino});

  final VecinoRanking vecino;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final controller = context.read<ComunidadController?>();

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => controller != null
                  ? ChangeNotifierProvider.value(
                value: controller,
                child: VecinoDetallePage(vecino: vecino),
              )
                  : VecinoDetallePage(vecino: vecino),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: colors.secondary.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '${vecino.posicion}°',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
              ),
              CircleAvatar(
                radius: 18,
                backgroundColor: vecino.esUsuarioActual
                    ? colors.primary
                    : colors.primaryContainer,
                child: Text(
                  vecino.iniciales,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: vecino.esUsuarioActual
                        ? colors.onPrimary
                        : colors.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vecino.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      'Nivel ${vecino.nivel}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${vecino.xpPeriodo} XP',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopThreeErrorBody extends StatelessWidget {
  const _TopThreeErrorBody({this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.error.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(
            'No se pudo cargar el Top 3 del mes del barrio.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: colors.error),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reintentar'),
            ),
          ],
        ],
      ),
    );
  }
}

class _EstadoErrorRanking extends StatelessWidget {
  const _EstadoErrorRanking({required this.onReintentar});

  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.error.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 36, color: colors.error),
            const SizedBox(height: 10),
            Text(
              'No se pudo cargar el ranking del barrio.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onReintentar,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EstadoVacioRanking extends StatelessWidget {
  const _EstadoVacioRanking({required this.onReintentar});

  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.emoji_people_outlined,
              size: 36,
              color: Color(0xFF006D77),
            ),
            const SizedBox(height: 10),
            const Text(
              'Aún no hay vecinos en el ranking del barrio este mes.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onReintentar,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaVecinoRanking extends StatelessWidget {
  const _FilaVecinoRanking({required this.vecino});

  final VecinoRanking vecino;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final esUsuario = vecino.esUsuarioActual;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: esUsuario ? const Color(0xFFE0F2F1) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            final controller = context.read<ComunidadController>();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider.value(
                  value: controller,
                  child: VecinoDetallePage(vecino: vecino),
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: esUsuario
                    ? theme.colorScheme.primary
                    : Colors.grey.withValues(alpha: 0.2),
                width: esUsuario ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '#${vecino.posicion}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: vecino.posicion <= 3
                          ? const Color(0xFFD48B00)
                          : Colors.grey[700],
                    ),
                  ),
                ),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: esUsuario
                      ? theme.colorScheme.primary
                      : Colors.grey[300],
                  child: Text(
                    vecino.iniciales,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: esUsuario ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vecino.nombre,
                        style: TextStyle(
                          fontWeight: esUsuario
                              ? FontWeight.bold
                              : FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Nivel ${vecino.nivel}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (vecino.insignias.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                vecino.insignias.first,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF8D6200),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _IndicadorTendencia(tendencia: vecino.tendencia),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${vecino.xpPeriodo} XP',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const Text(
                      'este mes',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Colors.grey.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IndicadorTendencia extends StatelessWidget {
  const _IndicadorTendencia({required this.tendencia});

  final TendenciaRanking tendencia;

  @override
  Widget build(BuildContext context) {
    return switch (tendencia) {
      TendenciaRanking.sube => const Icon(
        Icons.trending_up,
        size: 18,
        color: Color(0xFF2A9D8F),
      ),
      TendenciaRanking.baja => const Icon(
        Icons.trending_down,
        size: 18,
        color: Color(0xFFC0392B),
      ),
      TendenciaRanking.igual => Icon(
        Icons.remove,
        size: 18,
        color: Colors.grey[400],
      ),
    };
  }
}
