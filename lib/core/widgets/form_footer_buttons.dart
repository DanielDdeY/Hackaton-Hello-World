import 'package:flutter/material.dart';

class FormFooterButtons extends StatelessWidget {
  const FormFooterButtons({super.key, required this.onPublish, this.onCancel});

  final VoidCallback? onPublish;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    const buttonSize = Size(0, 48);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: buttonSize),
            onPressed: onCancel ?? () => Navigator.of(context).pop(),
            child: const Text('Cancelar', textAlign: TextAlign.center),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            style: FilledButton.styleFrom(minimumSize: buttonSize),
            onPressed: onPublish,
            child: const Text('Publicar', textAlign: TextAlign.center),
          ),
        ),
      ],
    );
  }
}
