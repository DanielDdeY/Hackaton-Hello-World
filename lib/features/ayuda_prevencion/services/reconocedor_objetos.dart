/// Contrato para el reconocimiento y clasificación de imágenes por computadora.
abstract interface class ReconocedorObjetos {
  /// Procesa la imagen en [imagePath] y retorna una lista de etiquetas descriptivas encontradas.
  Future<List<String>> detectarEtiquetas(String imagePath);

  /// Libera recursos del modelo de detección.
  Future<void> dispose();
}

