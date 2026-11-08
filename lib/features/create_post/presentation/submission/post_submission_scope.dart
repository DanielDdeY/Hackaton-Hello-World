import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/form_footer_buttons.dart';
import '../../domain/entities/post_failure.dart';
import '../../domain/entities/post_form_data.dart';
import '../../domain/services/auth_gateway.dart';
import '../../domain/services/post_repository.dart';
import 'post_submission_controller.dart';

class PostSubmissionScope extends StatefulWidget {
  const PostSubmissionScope({
    super.key,
    required this.formKey,
    required this.readData,
    required this.builder,
    this.prepare,
  });

  final GlobalKey<FormState> formKey;
  final PostFormData Function() readData;
  final Widget Function(BuildContext, VoidCallback onCancel, Widget footer)
  builder;
  final Future<void> Function()? prepare;

  @override
  State<PostSubmissionScope> createState() => _PostSubmissionScopeState();
}

class _PostSubmissionScopeState extends State<PostSubmissionScope> {
  late final _submission = PostSubmissionController(
    auth: context.read<AuthGateway?>(),
    repository: context.read<PostRepository?>(),
  );
  DialogRoute<bool>? _confirmDialog;

  Future<void> _publish() async {
    if (_submission.isBusy || widget.formKey.currentState?.validate() != true) {
      return;
    }
    FocusScope.of(context).unfocus();
    final id = await _submission.submit(
      widget.readData,
      prepare: widget.prepare,
    );
    if (!mounted) return;
    if (id != null) {
      final navigator = Navigator.of(context);
      final confirmation = _confirmDialog;
      if (confirmation != null && confirmation.isActive) {
        navigator.removeRoute(confirmation);
      }
      final messenger = ScaffoldMessenger.of(context);
      navigator.pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Publicación creada.')));
      return;
    }
    final failure = _submission.failure;
    if (failure != null && failure != PostFailureReason.cancelled) {
      _showMessage(_errorMessage(failure));
    }
  }

  Future<void> _cancel() async {
    final navigator = Navigator.of(context);
    if (!_submission.isBusy) {
      navigator.pop();
      return;
    }
    if (!_submission.canCancel || _confirmDialog != null) return;

    final dialog = DialogRoute<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cancelar la subida?'),
        content: const Text(
          'Se eliminarán las fotos subidas de esta publicación.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Seguir subiendo'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancelar subida'),
          ),
        ],
      ),
    );
    _confirmDialog = dialog;
    final confirmed = await navigator.push(dialog);
    _confirmDialog = null;
    if (!mounted || confirmed != true) return;
    final cancelled = await _submission.cancelUpload();
    if (mounted && cancelled && ModalRoute.of(context)?.isCurrent == true) {
      navigator.pop();
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _errorMessage(PostFailureReason failure) => switch (failure) {
    PostFailureReason.invalid =>
      'Revisa los campos obligatorios y vuelve a publicar.',
    PostFailureReason.noSession =>
      'No se pudo iniciar sesión. Vuelve a tocar Publicar.',
    PostFailureReason.anonymousDisabled =>
      'El acceso anónimo no está habilitado. Intenta publicar más tarde.',
    PostFailureReason.offline =>
      'Sin conexión. Conéctate y vuelve a tocar Publicar.',
    PostFailureReason.timeout =>
      'La operación tardó demasiado. Puedes reintentar.',
    PostFailureReason.tooLarge =>
      'La foto debe pesar menos de 5 MB. Elige otra foto.',
    PostFailureReason.invalidPhoto =>
      'Elige una foto en formato JPG y vuelve a publicar.',
    PostFailureReason.permissionDenied =>
      'Firebase rechazó la operación por falta de permisos.',
    PostFailureReason.cancelled => 'Se canceló la subida.',
    PostFailureReason.upload => 'No se pudo subir la foto. Puedes reintentar.',
    PostFailureReason.save =>
      'No se pudo guardar la publicación. Puedes reintentar.',
    PostFailureReason.cleanup => 'No se pudo confirmar la eliminación de todos los archivos de esta subida.',
  };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _submission,
      builder: (context, _) => PopScope<Object?>(
        canPop: !_submission.isBusy,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && _submission.canCancel) _cancel();
        },
        child: widget.builder(
          context,
          _cancel,
          FormFooterButtons(
            onPublish: _publish,
            onCancel: _cancel,
            cancelEnabled: !_submission.isBusy || _submission.canCancel,
            publishBusy: _submission.isBusy,
            progress: _submission.isCancelling ? null : _submission.progress,
            publishBusyLabel: _submission.isCancelling
                ? 'Cancelando…'
                : _submission.state == PostSubmissionState.uploading
                ? 'Subiendo…'
                : 'Publicando…',
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _submission.dispose();
    super.dispose();
  }
}
