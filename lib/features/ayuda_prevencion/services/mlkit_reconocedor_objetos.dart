import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

import 'reconocedor_objetos.dart';

/// Implementación de [ReconocedorObjetos] basada en Google ML Kit Image Labeling on-device.
class MlKitReconocedorObjetos implements ReconocedorObjetos {
  MlKitReconocedorObjetos({double umbralConfianza = 0.55})
      : _labeler = ImageLabeler(
          options: ImageLabelerOptions(confidenceThreshold: umbralConfianza),
        );

  final ImageLabeler _labeler;

  @override
  Future<List<String>> detectarEtiquetas(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final labels = await _labeler.processImage(inputImage);
    return labels.map((l) => l.label.toLowerCase()).toList();
  }

  @override
  Future<void> dispose() async {
    await _labeler.close();
  }
}

