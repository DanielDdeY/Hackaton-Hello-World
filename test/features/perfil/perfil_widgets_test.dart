import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackaton_hello_world/features/perfil/presentation/widgets/widgets.dart';

void main() {
  group('CatalogoInsignias', () {
    test('resuelve insignias conocidas con sus propiedades oficiales', () {
      final preparado = CatalogoInsignias.resolver('vecino-preparado');
      expect(preparado.nombre, 'Vecino preparado');
      expect(preparado.icono, Icons.backpack_outlined);

      final solidario = CatalogoInsignias.resolver('vecino-solidario');
      expect(solidario.nombre, 'Vecino solidario');
      expect(solidario.icono, Icons.volunteer_activism_outlined);

      final alerta = CatalogoInsignias.resolver('vecino-alerta');
      expect(alerta.nombre, 'Vecino alerta');
      expect(alerta.icono, Icons.notifications_active_outlined);
    });

    test('formatea slugs desconocidos a formato legible con icono por defecto', () {
      final dinamica = CatalogoInsignias.resolver('guardian-del-barrio');
      expect(dinamica.nombre, 'Guardian Del Barrio');
      expect(dinamica.icono, Icons.military_tech_outlined);
    });
  });

  group('PerfilCabecera', () {
    testWidgets('renderiza iniciales, nombre, distrito, nivel y barra de progreso', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PerfilCabecera(
              nombre: 'Carlos Huamán',
              iniciales: 'CH',
              distrito: 'Ate',
              provincia: 'Lima',
              xp: 150,
            ),
          ),
        ),
      );

      expect(find.text('CH'), findsOneWidget);
      expect(find.text('Carlos Huamán'), findsOneWidget);
      expect(find.text('Ate, Lima'), findsOneWidget);
      expect(find.textContaining('Nivel 1'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('50 / 110 XP'), findsOneWidget);
      expect(find.textContaining('Faltan 60 XP'), findsOneWidget);
    });
  });

  group('PerfilResumen', () {
    testWidgets('muestra métricas económicas clave de forma organizada', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PerfilResumen(
              xpMes: 80,
              fichas: 125,
              estrellas: 4.8,
              totalResenas: 12,
            ),
          ),
        ),
      );

      expect(find.text('80'), findsOneWidget);
      expect(find.text('XP del mes'), findsOneWidget);
      expect(find.text('125'), findsOneWidget);
      expect(find.text('Fichas'), findsOneWidget);
      expect(find.text('4.8'), findsOneWidget);
      expect(find.text('★ (12)'), findsOneWidget);
    });
  });

  group('PerfilTarjetasDestacadas', () {
    testWidgets('muestra estado de mascota y mochila y responde a toques', (tester) async {
      var mascotaTocada = false;
      var mochilaTocada = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PerfilTarjetasDestacadas(
              xp: 220, // Nivel 2 -> mascota desbloqueada
              bonoMochilaReclamado: true,
              itemsMochilaListos: 10,
              onAbrirMascota: () => mascotaTocada = true,
              onAbrirMochila: () => mochilaTocada = true,
            ),
          ),
        ),
      );

      expect(find.text('Mi Mascota Vecinal'), findsOneWidget);
      expect(find.textContaining('¡Tu cuy está activo!'), findsOneWidget);
      expect(find.text('Mochila de Emergencia'), findsOneWidget);
      expect(find.text('Verificada'), findsOneWidget);

      await tester.tap(find.text('Mi Mascota Vecinal'));
      await tester.pump();
      expect(mascotaTocada, isTrue);

      await tester.tap(find.text('Mochila de Emergencia'));
      await tester.pump();
      expect(mochilaTocada, isTrue);
    });
  });

  group('PerfilInsignias', () {
    testWidgets('muestra mensaje vacío si no tiene insignias', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PerfilInsignias(insignias: []),
          ),
        ),
      );

      expect(find.text('Insignias y logros'), findsOneWidget);
      expect(find.textContaining('Aún no tienes insignias'), findsOneWidget);
    });

    testWidgets('muestra chips con nombres del catálogo y abre modal al tocar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PerfilInsignias(
              insignias: ['vecino-preparado', 'vecino-solidario'],
            ),
          ),
        ),
      );

      expect(find.text('Vecino preparado'), findsOneWidget);
      expect(find.text('Vecino solidario'), findsOneWidget);

      await tester.tap(find.text('Vecino preparado'));
      await tester.pumpAndSettle();

      expect(find.textContaining('mochila de emergencia'), findsOneWidget);
      expect(find.text('Entendido'), findsOneWidget);
    });
  });

  group('PerfilActividad', () {
    testWidgets('muestra los 4 indicadores de actividad comunitaria', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PerfilActividad(
              favoresCompletados: 14,
              eventosAsistidos: 6,
              reconocimientos: 25,
              rachaSemanal: 3,
            ),
          ),
        ),
      );

      expect(find.text('14'), findsOneWidget);
      expect(find.text('Favores listos'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.text('Eventos asistidos'), findsOneWidget);
      expect(find.text('25'), findsOneWidget);
      expect(find.text('Reconocimientos'), findsOneWidget);
      expect(find.text('3 sem'), findsOneWidget);
      expect(find.text('Racha activa'), findsOneWidget);
    });
  });

  group('PerfilDatosPersonales', () {
    testWidgets('enmascara el teléfono y conmuta visibilidad al tocar el ojo', (tester) async {
      var editarTocado = false;
      var sosTocado = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PerfilDatosPersonales(
              zona: 'Ate, Lima, Lima',
              telefono: '987654321',
              bio: 'Vecino del barrio desde hace 5 años.',
              onEditar: () => editarTocado = true,
              onContactosSos: () => sosTocado = true,
            ),
          ),
        ),
      );

      expect(find.text('Ate, Lima, Lima'), findsOneWidget);
      expect(find.text('Vecino del barrio desde hace 5 años.'), findsOneWidget);
      // Teléfono enmascarado
      expect(find.text('987 ••• •21'), findsOneWidget);
      expect(find.text('987654321'), findsNothing);

      // Tocar botón de ojo para revelar
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();
      expect(find.text('987654321'), findsOneWidget);

      // Tocar botones de acción
      await tester.tap(find.text('Editar datos'));
      await tester.pump();
      expect(editarTocado, isTrue);

      await tester.tap(find.text('Contactos SOS'));
      await tester.pump();
      expect(sosTocado, isTrue);
    });
  });
}

