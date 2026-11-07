import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../errors/photo_picker_failure.dart';
import 'dashed_action_box.dart';

enum _PhotoSource { camera, gallery }

class OptionalPhotoPicker extends StatefulWidget {
  const OptionalPhotoPicker({
    super.key,
    required this.label,
    required this.photoPaths,
    required this.onChanged,
    this.maxPhotos = 1,
    this.pickFromCamera,
    this.pickFromGallery,
  }) : assert(pickFromCamera != null || pickFromGallery != null),
       assert(maxPhotos > 0);

  final String label;
  final List<String> photoPaths;
  final int maxPhotos;
  final ValueChanged<List<String>> onChanged;
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
    if (_isPicking || widget.photoPaths.length >= widget.maxPhotos) return;
    setState(() => _isPicking = true);
    String? path;
    try {
      path = await _choosePhoto();
    } on Exception catch (error) {
      if (mounted) {
        final message = switch (error) {
          PhotoPickerFailure(reason: PhotoPickerFailureReason.cameraDenied) =>
            'Permite el acceso a la cámara en los ajustes del dispositivo.',
          PhotoPickerFailure(reason: PhotoPickerFailureReason.galleryDenied) =>
            'Permite el acceso a tus fotos en los ajustes del dispositivo.',
          _ => 'No se pudo adjuntar la foto.',
        };
        ScaffoldMessenger.maybeOf(context)
            ?.showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }

    if (mounted &&
        path != null &&
        widget.photoPaths.length < widget.maxPhotos) {
      widget.onChanged([...widget.photoPaths, path]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final paths = widget.photoPaths;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < paths.length; index++)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: _PhotoPreview(path: paths[index]),
            title: Text(
              widget.maxPhotos == 1 ? 'Foto adjunta' : 'Foto ${index + 1}',
            ),
            trailing: IconButton(
              tooltip: widget.maxPhotos == 1
                  ? 'Quitar foto'
                  : 'Quitar foto ${index + 1}',
              onPressed: () => widget.onChanged([...paths]..removeAt(index)),
              icon: const Icon(Icons.close),
            ),
          ),
        if (paths.length < widget.maxPhotos)
          Semantics(
            liveRegion: _isPicking,
            child: DashedActionBox(
              label: _isPicking ? 'Seleccionando foto…' : widget.label,
              icon:
                  widget.pickFromCamera != null &&
                      widget.pickFromGallery == null
                  ? Icons.photo_camera_outlined
                  : Icons.add_photo_alternate_outlined,
              onTap: _isPicking ? null : _attachPhoto,
            ),
          ),
      ],
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    const size = 44.0;
    Widget fallback(BuildContext context, Object error, StackTrace? stack) =>
        const Icon(Icons.image_outlined);

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox.square(
        dimension: size,
        child: kIsWeb
            ? Image.network(path, fit: BoxFit.cover, errorBuilder: fallback)
            : Image.file(
                File(path),
                fit: BoxFit.cover,
                cacheWidth: 144,
                errorBuilder: fallback,
              ),
      ),
    );
  }
}
