import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/vecino_ranking.dart';
import '../domain/entities/recognition.dart';
import '../domain/services/recognition_repository.dart';
import 'recognize_neighbor_controller.dart';

Future<void> showRecognizeNeighborSheet(
  BuildContext context, {
  required List<VecinoRanking> neighbors,
  required String currentUid,
  required RecognitionRepository repository,
}) {
  final messenger = ScaffoldMessenger.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: false,
    enableDrag: false,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (_) => ChangeNotifierProvider(
      create: (_) => RecognizeNeighborController(repository),
      child: _RecognizeNeighborSheet(
        neighbors: [
          for (final neighbor in neighbors)
            if (neighbor.uid.isNotEmpty && neighbor.uid != currentUid) neighbor,
        ],
        messenger: messenger,
      ),
    ),
  );
}

class _RecognizeNeighborSheet extends StatefulWidget {
  const _RecognizeNeighborSheet({
    required this.neighbors,
    required this.messenger,
  });

  final List<VecinoRanking> neighbors;
  final ScaffoldMessengerState messenger;

  @override
  State<_RecognizeNeighborSheet> createState() =>
      _RecognizeNeighborSheetState();
}

class _RecognizeNeighborSheetState extends State<_RecognizeNeighborSheet> {
  final _search = TextEditingController();
  final _message = TextEditingController();
  VecinoRanking? _selected;

  @override
  void dispose() {
    _search.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _send(
    VecinoRanking neighbor,
    RecognizeNeighborController controller,
  ) async {
    final draft = RecognitionDraft(
      recipientId: neighbor.uid,
      recipientName: neighbor.nombre,
      districtId: neighbor.distrito,
      message: _message.text,
    );
    final sent = await controller.send(draft);
    if (!mounted || !sent) return;

    final messenger = widget.messenger;
    Navigator.of(context).pop();
    if (messenger.mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Reconocimiento enviado a ${neighbor.nombre}. '
            'Aparecerá en su resumen de fin de mes.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RecognizeNeighborController>();
    final selected = _selected;
    final theme = Theme.of(context);
    return PopScope(
      canPop: !controller.isSaving,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.72,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Reconocer a un vecino',
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      onPressed: controller.isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                      tooltip: 'Cerrar',
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (selected == null)
                  ..._picker(theme)
                else
                  ..._composer(theme, selected, controller),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _picker(ThemeData theme) {
    final query = _search.text.trim().toLowerCase();
    final matches = widget.neighbors.where(
      (neighbor) => neighbor.nombre.toLowerCase().contains(query),
    );
    return [
      TextField(
        controller: _search,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          labelText: 'Buscar por nombre',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      if (matches.isEmpty)
        Text(
          query.isEmpty
              ? 'Aún no hay otros vecinos en la lista de tu barrio.'
              : 'No encontramos vecinos con ese nombre.',
        ),
      for (final neighbor in matches)
        Card(
          child: ListTile(
            leading: CircleAvatar(child: Text(neighbor.iniciales)),
            title: Text(neighbor.nombre),
            subtitle: Text(
              'Nivel ${neighbor.nivel} · ${neighbor.xpPeriodo} XP este mes',
              style: theme.textTheme.bodySmall,
            ),
            trailing: Text('#${neighbor.posicion}'),
            onTap: () {
              FocusScope.of(context).unfocus();
              setState(() => _selected = neighbor);
            },
          ),
        ),
    ];
  }

  List<Widget> _composer(
    ThemeData theme,
    VecinoRanking neighbor,
    RecognizeNeighborController controller,
  ) {
    final length = _message.text.trim().runes.length;
    final failure = controller.failure;
    final busy = controller.isSaving;
    return [
      Text('Para ${neighbor.nombre}', style: theme.textTheme.titleMedium),
      const SizedBox(height: 12),
      TextField(
        controller: _message,
        enabled: !busy,
        minLines: 3,
        maxLines: 6,
        textCapitalization: TextCapitalization.sentences,
        keyboardType: TextInputType.multiline,
        onChanged: (_) {
          controller.clearFailure();
          setState(() {});
        },
        decoration: InputDecoration(
          labelText: 'Mensaje',
          hintText: 'Cuéntale qué buena acción quieres reconocer.',
          alignLabelWithHint: true,
          border: const OutlineInputBorder(),
          counterText: '$length/${RecognitionDraft.messageLimit}',
          errorText: length > RecognitionDraft.messageLimit
              ? 'El mensaje debe tener hasta 280 caracteres.'
              : null,
        ),
      ),
      if (failure != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Semantics(
            liveRegion: true,
            child: Text(
              _failureMessage(failure),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          TextButton(
            onPressed: busy
                ? null
                : () {
                    controller.clearFailure();
                    setState(() => _selected = null);
                  },
            child: const Text('Cambiar vecino'),
          ),
          FilledButton(
            onPressed:
                busy || length < 1 || length > RecognitionDraft.messageLimit
                ? null
                : () => _send(neighbor, controller),
            child: busy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      semanticsLabel: 'Enviando reconocimiento',
                    ),
                  )
                : const Text('Enviar'),
          ),
        ],
      ),
    ];
  }

  static String _failureMessage(RecognitionFailureReason reason) =>
      switch (reason) {
        RecognitionFailureReason.noSession =>
          'Tu sesión no está disponible. Vuelve a iniciar sesión.',
        RecognitionFailureReason.offline =>
          'Necesitas conexión para enviar el reconocimiento. Intenta de nuevo.',
        RecognitionFailureReason.permissionDenied => 'No tienes permiso para reconocer a este vecino. Comprueba que ambos pertenecen al mismo barrio.',
        RecognitionFailureReason.duplicate =>
          'Ya reconociste a este vecino este mes.',
        RecognitionFailureReason.invalid =>
          'Elige a otro vecino y escribe un mensaje de 1 a 280 caracteres.',
        RecognitionFailureReason.unavailable =>
          'No se pudo enviar el reconocimiento. Intenta de nuevo.',
      };
}
