import 'package:flutter/material.dart';

/// Muestra el aviso de responsabilidad antes de activar el SOS.
///
/// Devuelve `true` solo si la persona marcó la casilla y confirmó.
Future<bool> confirmSosActivation(BuildContext context) async {
  final accepted = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const SosConfirmationSheet(),
  );
  return accepted == true;
}

class SosConfirmationSheet extends StatefulWidget {
  const SosConfirmationSheet({super.key});

  @override
  State<SosConfirmationSheet> createState() => _SosConfirmationSheetState();
}

class _SosConfirmationSheetState extends State<SosConfirmationSheet> {
  bool _accepted = false;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xffb71c1c),
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Activar alerta SOS',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Usa el SOS solo para emergencias reales. Una alerta falsa '
            'moviliza a tus vecinos y queda bajo tu responsabilidad.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _accepted,
            onChanged: (value) => setState(() => _accepted = value ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text(
              'Entiendo y asumo la responsabilidad',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xffb71c1c),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _accepted
                      ? () => Navigator.of(context).pop(true)
                      : null,
                  child: const Text('Activar SOS'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
