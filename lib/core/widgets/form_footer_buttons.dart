import 'package:flutter/material.dart';

class FormFooterButtons extends StatefulWidget {
  const FormFooterButtons({
    super.key,
    required this.onPublish,
    this.onCancel,
    this.cancelEnabled = true,
    this.publishBusy = false,
    this.progress,
    this.publishBusyLabel = 'Verificando sesión',
  });

  final Future<void> Function()? onPublish;
  final VoidCallback? onCancel;
  final bool cancelEnabled;
  final bool publishBusy;
  final double? progress;
  final String publishBusyLabel;

  @override
  State<FormFooterButtons> createState() => _FormFooterButtonsState();
}

class _FormFooterButtonsState extends State<FormFooterButtons> {
  bool _publishing = false;

  Future<void> _publish() async {
    final publish = widget.onPublish;
    if (_publishing || widget.publishBusy || publish == null) return;
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
    final busy = _publishing || widget.publishBusy;
    final progress = widget.progress;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: buttonSize),
            onPressed: widget.cancelEnabled
                ? widget.onCancel ?? () => Navigator.of(context).pop()
                : null,
            child: const Text('Cancelar', textAlign: TextAlign.center),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            style: FilledButton.styleFrom(minimumSize: buttonSize),
            onPressed: busy || widget.onPublish == null ? null : _publish,
            child: busy
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 2,
                          semanticsLabel: widget.publishBusyLabel,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          progress == null
                              ? widget.publishBusyLabel
                              : '${(progress * 100).round()} %',
                        ),
                      ),
                    ],
                  )
                : const Text('Publicar', textAlign: TextAlign.center),
          ),
        ),
      ],
    );
  }
}
