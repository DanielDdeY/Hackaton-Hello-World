import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackaton_hello_world/features/ayuda_prevencion/services/backpack_checklist_store.dart';
import 'package:hackaton_hello_world/features/ayuda_prevencion/services/mochila_etiquetas_catalogo.dart';
import 'package:hackaton_hello_world/features/ayuda_prevencion/services/reconocedor_objetos.dart';
import 'package:hackaton_hello_world/features/ayuda_prevencion/widgets/mochila_emergencia_card.dart';
import 'package:hackaton_hello_world/features/create_post/domain/services/photo_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeReconocedor implements ReconocedorObjetos {
  _FakeReconocedor(this.etiquetasADevolver);

  final List<String> etiquetasADevolver;
  bool disposed = false;

  @override
  Future<List<String>> detectarEtiquetas(String imagePath) async {
    return etiquetasADevolver;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

class _FakePhotoPicker implements PhotoPicker {
  _FakePhotoPicker({this.pathADevolver = '/tmp/fake_photo.jpg'});

  final String? pathADevolver;

  @override
  Future<String?> pickFromCamera() async => pathADevolver;

  @override
  Future<String?> pickFromGallery() async => pathADevolver;

  @override
  Future<Uint8List> readPhoto(String path) async => Uint8List(0);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('MochilaEtiquetasCatalogo', () {
    test('coincide correctamente con etiquetas esperadas en inglés', () {
      expect(
        MochilaEtiquetasCatalogo.coincideConItem('Agua', ['mineral water', 'drink']),
        isTrue,
      );
      expect(
        MochilaEtiquetasCatalogo.coincideConItem('Linterna', ['flashlight']),
        isTrue,
      );
      expect(
        MochilaEtiquetasCatalogo.coincideConItem('Alimentos no perecibles', ['can', 'food']),
        isTrue,
      );
      expect(
        MochilaEtiquetasCatalogo.coincideConItem('Radio', ['electronic device']),
        isTrue,
      );
      expect(
        MochilaEtiquetasCatalogo.coincideConItem('Botiquín', ['first aid', 'medicine']),
        isTrue,
      );
    });

    test('rechaza etiquetas no relacionadas', () {
      expect(
        MochilaEtiquetasCatalogo.coincideConItem('Agua', ['car', 'chair', 'tree']),
        isFalse,
      );
      expect(
        MochilaEtiquetasCatalogo.etiquetaCoincidente('Linterna', ['dog', 'cat']),
        isNull,
      );
    });
  });

  group('BackpackChecklistStore fotos por elemento', () {
    test('guarda, lee y elimina fotos individuales por elemento de la mochila', () async {
      var fotos = await BackpackChecklistStore.loadItemPhotos();
      expect(fotos, isEmpty);

      await BackpackChecklistStore.saveItemPhoto('Agua', '/storage/agua.jpg');
      await BackpackChecklistStore.saveItemPhoto('Linterna', '/storage/linterna.jpg');

      fotos = await BackpackChecklistStore.loadItemPhotos();
      expect(fotos['Agua'], '/storage/agua.jpg');
      expect(fotos['Linterna'], '/storage/linterna.jpg');

      await BackpackChecklistStore.removeItemPhoto('Agua');
      fotos = await BackpackChecklistStore.loadItemPhotos();
      expect(fotos.containsKey('Agua'), isFalse);
      expect(fotos['Linterna'], '/storage/linterna.jpg');
    });
  });

  group('MochilaEmergenciaCard detección ML Kit y fotos', () {
    testWidgets('reconoce automáticamente elemento coincidente y lo verifica al confirmar', (
      tester,
    ) async {
      final fakeReconocedor = _FakeReconocedor(['plastic bottle', 'liquid']);
      final fakePicker = _FakePhotoPicker(pathADevolver: '/tmp/botella.jpg');

      await tester.binding.setSurfaceSize(const Size(600, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MochilaEmergenciaCard(
              reconocedor: fakeReconocedor,
              photoPicker: fakePicker,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Abrir modal de verificación de fotos
      await tester.tap(find.text('Verificar con foto'));
      await tester.pumpAndSettle();

      expect(find.text('Verificación con fotos (ML Kit)'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'Agua'), findsOneWidget);

      // Tocar botón Foto para 'Agua'
      await tester.tap(find.widgetWithText(OutlinedButton, 'Foto').first);
      await tester.pumpAndSettle();

      // Diálogo de detección positiva
      expect(find.text('¡Elemento detectado!'), findsOneWidget);
      expect(find.textContaining('plastic bottle'), findsOneWidget);

      // Confirmar
      await tester.tap(find.text('Verificar elemento'));
      await tester.pumpAndSettle();

      // Comprobar que 'Agua' ahora tiene foto y está marcado
      final chipAgua = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'Agua'),
      );
      expect(chipAgua.selected, isTrue);

      final fotosGuardadas = await BackpackChecklistStore.loadItemPhotos();
      expect(fotosGuardadas['Agua'], '/tmp/botella.jpg');
    });

    testWidgets('permite confirmación manual si ML Kit no reconoce con certeza la etiqueta', (
      tester,
    ) async {
      final fakeReconocedor = _FakeReconocedor(['indoor', 'furniture']);
      final fakePicker = _FakePhotoPicker(pathADevolver: '/tmp/linterna.jpg');

      await tester.binding.setSurfaceSize(const Size(600, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MochilaEmergenciaCard(
              reconocedor: fakeReconocedor,
              photoPicker: fakePicker,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Verificar con foto'));
      await tester.pumpAndSettle();

      // Tocar botón Foto para el tercer elemento (Linterna)
      await tester.tap(find.widgetWithText(OutlinedButton, 'Foto').at(2));
      await tester.pumpAndSettle();

      // Diálogo de confirmación manual
      expect(find.text('Foto de Linterna'), findsOneWidget);
      expect(find.textContaining('No pudimos confirmar automáticamente'), findsOneWidget);

      await tester.tap(find.text('Guardar foto'));
      await tester.pumpAndSettle();

      final chipLinterna = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'Linterna'),
      );
      expect(chipLinterna.selected, isTrue);

      final fotosGuardadas = await BackpackChecklistStore.loadItemPhotos();
      expect(fotosGuardadas['Linterna'], '/tmp/linterna.jpg');
    });
  });
}

