import 'package:flutter/material.dart';

class FormFooterButtons extends StatefulWidget {
  const FormFooterButtons({super.key, required this.onPublish, this.onCancel});

  final Future<void> Function()? onPublish;
  final VoidCallback? onCancel;

  @override
  State<FormFooterButtons> createState() => _FormFooterButtonsState();
}

class _FormFooterButtonsState extends State<FormFooterButtons> {
  bool _publishing = false;

  Future<void> _publish() async {
    final publish = widget.onPublish;
    if (_publishing || publish == null) return;
    setState(() => _publishing = true);
    try {
      await publish();
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const buttonSize = Size(0, 48);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: buttonSize),
            onPressed: widget.onCancel ?? () => Navigator.of(context).pop(),
            child: const Text('Cancelar', textAlign: TextAlign.center),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            style: FilledButton.styleFrom(minimumSize: buttonSize),
            onPressed: _publishing || widget.onPublish == null
                ? null
                : _publish,
            child: _publishing
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      semanticsLabel: 'Verificando sesión',
                    ),
                  )
                : const Text('Publicar', textAlign: TextAlign.center),
          ),
        ),
      ],
    );
  }
}
