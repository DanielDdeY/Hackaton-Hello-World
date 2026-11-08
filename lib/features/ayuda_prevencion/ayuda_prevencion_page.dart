import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../create_post/domain/services/photo_picker.dart';
import 'services/reconocedor_objetos.dart';
import 'widgets/directorio_seccion.dart';
import 'widgets/mochila_emergencia_card.dart';
import 'widgets/servicios_cercanos_section.dart';
import 'widgets/simulacro_video_page.dart';
import 'widgets/tutorial_card.dart';

/// Pantalla "Ayuda y Prevención".
///
/// Compone: Mochila de Emergencia, Tutorial Paso a Paso,
/// Directorio de Emergencia (offline) y Servicios cercanos (GPS + Overpass).
class AyudaPrevencionPage extends StatelessWidget {
  const AyudaPrevencionPage({
    super.key,
    this.simulacroPageBuilder,
    this.reconocedor,
    this.photoPicker,
  });

  final WidgetBuilder? simulacroPageBuilder;
  final ReconocedorObjetos? reconocedor;
  final PhotoPicker? photoPicker;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        MochilaEmergenciaCard(
          reconocedor: reconocedor,
          photoPicker: photoPicker,
        ),
        const SizedBox(height: 12),
        _SimulacroButton(pageBuilder: simulacroPageBuilder),
        const SizedBox(height: 12),
        TutorialCard(),
        const SizedBox(height: 12),
        DirectorioSeccion(),
        const SizedBox(height: 12),
        ServiciosCercanosSection(),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'En una emergencia, llama primero y describe: qué pasó, '
            'dónde estás y cuántas personas hay.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.secondaryText,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}

class _SimulacroButton extends StatelessWidget {
  const _SimulacroButton({this.pageBuilder});

  final WidgetBuilder? pageBuilder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: pageBuilder ?? (_) => const SimulacroVideoPage(),
            ),
          );
        },
        icon: const Icon(Icons.play_circle_outline),
        label: const Text('Prepárate para un simulacro'),
      ),
    );
  }
}
