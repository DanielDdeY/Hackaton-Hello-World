import 'package:flutter/material.dart';

import '../controllers/comunidad_controller.dart';

/// Diálogo reutilizable para reconocer (nominar) a un vecino con un motivo.
Future<void> mostrarDialogoReconocimiento(
  BuildContext context,
  ComunidadController controller, {
  required String destinoUid,
  required String destinoNombre,
}) async {
  final motivoCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();

  await showDialog<void>(
    context: context,
    builder: (dialogCtx) {
      return AlertDialog(
        title: Text('Reconocer a $destinoNombre'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Destaca una buena acción vecinal de este vecino:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: motivoCtrl,
                maxLines: 3,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Ej. Ayudó a limpiar el pasaje tras la lluvia...',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 6) {
                    return 'Ingresa al menos una frase describiendo el motivo.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                await controller.nominarBuenVecino(
                  destinoUid,
                  motivoCtrl.text.trim(),
                );
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('¡Reconocimiento enviado con éxito!'),
                      backgroundColor: Color(0xFF2A9D8F),
                    ),
                  );
                }
              } catch (_) {
                if (dialogCtx.mounted) return;
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No se pudo enviar el reconocimiento.'),
                    ),
                  );
                }
              }
            },
            child: const Text('Enviar reconocimiento'),
          ),
        ],
      );
    },
  );
}
