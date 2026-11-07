import 'package:flutter/material.dart';

import 'dashed_action_box.dart';

enum _PhotoSource { camera, gallery }

class OptionalPhotoPicker extends StatefulWidget {
  const OptionalPhotoPicker({
    super.key,
    required this.label,
    required this.photoPath,
    required this.onChanged,
    this.pickFromCamera,
    this.pickFromGallery,
  }) : assert(pickFromCamera != null || pickFromGallery != null);

  final String label;
  final String? photoPath;
  final ValueChanged<String?> onChanged;
  final Future<String?> Function()? pickFromCamera;
  final Future<String?> Function()? pickFromGallery;

  @override
  State<OptionalPhotoPicker> createState() => _OptionalPhotoPickerState();
}

class _OptionalPhotoPickerState extends State<OptionalPhotoPicker> {
  bool _isPicking = false;

  Future<String?> _choosePhoto() async {
    final camera = widget.pickFromCamera;
    final gallery = widget.pickFromGallery;
    if (camera == null) return gallery!();
    if (gallery == null) return camera();

    final source = await showModalBottomSheet<_PhotoSource>(
      context: context,
      barrierLabel: 'Cerrar opciones de foto',
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(sheetContext, _PhotoSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(sheetContext, _PhotoSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (!mounted || source == null) return null;
    return source == _PhotoSource.camera ? camera() : gallery();
  }

  Future<void> _attachPhoto() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final path = await _choosePhoto();
      if (mounted && path != null) widget.onChanged(path);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text('No se pudo adjuntar la foto.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.photoPath != null) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.image_outlined),
        title: const Text('Foto adjunta'),
        trailing: IconButton(
          tooltip: 'Quitar foto',
          onPressed: () => widget.onChanged(null),
          icon: const Icon(Icons.close),
        ),
      );
    }

    return Semantics(
      liveRegion: _isPicking,
      child: DashedActionBox(
        label: _isPicking ? 'Seleccionando foto…' : widget.label,
        icon: widget.pickFromCamera != null && widget.pickFromGallery == null
            ? Icons.photo_camera_outlined
            : Icons.add_photo_alternate_outlined,
        onTap: _isPicking ? null : _attachPhoto,
      ),
    );
  }
}
