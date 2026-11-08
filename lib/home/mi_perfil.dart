part of 'home.dart';

class _MiPerfilPage extends StatelessWidget {
  const _MiPerfilPage({required this.datos});

  final _DatosBarrio datos;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.read<AuthGateway?>();
    final users = context.read<UserRepository?>();
    final uid = auth?.currentUid;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: StreamBuilder<AppUser>(
        stream: users != null && uid != null && uid.isNotEmpty
            ? users.watchUserStats(uid)
            : null,
        builder: (context, snapshot) {
          final stats = snapshot.data;
          if (stats != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              datos.syncEconomy(stats);
            });
          }
          return ListenableBuilder(
            listenable: datos,
            builder: (context, _) {
              final xp = stats?.xpTotal ?? datos.xp;
              final nivel = stats?.level ?? datos.nivel;
              final star = stats != null && stats.reviewCount > 0
                  ? stats.averageStars.round()
                  : datos.stars;
              final monedas = stats?.availableCoins ?? datos.fichas;
              final xpMes = stats?.effectiveMonthlyXp ?? datos.weeklyXp;

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 36,
                      child: Text(
                        datos.iniciales,
                        style: theme.textTheme.headlineSmall,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(datos.nombre, style: theme.textTheme.headlineSmall),
                  Text(datos.rol, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 16),
                  if (datos.bio.isNotEmpty) ...[
                    Text(datos.bio),
                    const SizedBox(height: 16),
                  ],
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.location_on_outlined),
                    title: const Text('Ubicación'),
                    subtitle: Text(
                      datos.zona.isEmpty ? 'No indicada' : datos.zona,
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.phone_outlined),
                    title: const Text('Teléfono'),
                    subtitle: SelectableText(
                      datos.phoneNumber.isEmpty
                          ? 'No indicado'
                          : datos.phoneNumber,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Tu participación', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    children: [
                      Text('Nivel $nivel · $xp XP · '),
                      SvgPicture.asset('assets/ficha.svg', width: 14, height: 14),
                      Text('$monedas fichas · $star ★'),
                    ],
                  ),
                  Text('$xpMes XP este mes en el barrio'),
                  Text('Favores completados: ${datos.favoresCompletados}'),
                  Text('Eventos asistidos: ${datos.eventosAsistidos}'),
                  Text('Reconocimientos: ${datos.reconocimientos}'),
                  Text('Racha semanal: ${datos.rachaSemanal}'),
                  if (datos.insignias.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('Insignias', style: theme.textTheme.titleMedium),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final insignia in datos.insignias)
                          Chip(label: Text(insignia)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => _EditarInformacionPage(datos: datos),
                      ),
                    ),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar información'),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}