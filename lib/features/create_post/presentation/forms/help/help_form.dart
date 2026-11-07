import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/validators/required_field_validator.dart';
import '../../../../../core/widgets/form_footer_buttons.dart';
import '../../../../../core/widgets/optional_photo_picker.dart';
import '../../../../comunidad/domain/entities/favor.dart';
import '../../../../comunidad/domain/repositories/comunidad_repository.dart';
import '../../../domain/services/photo_picker.dart';
import 'help_details_section.dart';
import 'help_form_controller.dart';

class HelpForm extends StatelessWidget {
  const HelpForm({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          HelpFormController(photoPicker: context.read<PhotoPicker>()),
      child: const _HelpFormView(),
    );
  }
}

class _HelpFormView extends StatefulWidget {
  const _HelpFormView();

  @override
  State<_HelpFormView> createState() => _HelpFormViewState();
}

class _HelpFormViewState extends State<_HelpFormView> {
  final _formKey = GlobalKey<FormState>();

  void _publish() async {
    if (!_formKey.currentState!.validate()) return;

    final data = context.read<HelpFormController>().data;

    // Registra el nuevo favor en el repositorio de comunidad
    final repo = context.read<ComunidadRepository?>();
    if (repo != null) {
      final desc = data.description.trim();
      final titulo = desc.length > 50 ? '${desc.substring(0, 47)}...' : desc;

      final nuevoFavor = Favor(
        id: 'fav_${DateTime.now().millisecondsSinceEpoch}',
        titulo: titulo,
        descripcion: desc,
        categoria: CategoriaFavor.otros,
        tamano: (data.peopleCount ?? 1) > 2 ? TamanoFavor.comunitario : TamanoFavor.medio,
        estado: EstadoFavor.abierto,
        cuposTotales: data.peopleCount ?? 1,
        cuposTomados: 0,
        solicitanteId: 'usr_actual',
        solicitanteNombre: 'Tú',
        solicitanteTelefono: '999888777',
        cuadraNombre: data.location?.isNotEmpty == true ? data.location! : 'Mi Cuadra',
        ubicacionAproximada: data.location?.isNotEmpty == true ? data.location! : 'En tu zona cercana',
        creadoEn: DateTime.now(),
        venceEn: data.neededBy ?? DateTime.now().add(const Duration(days: 1)),
        monedasRecompensa: TamanoFavor.medio.monedasBase,
        xpRecompensa: TamanoFavor.medio.xpBase,
      );

      await repo.agregarFavor(nuevoFavor);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Pedido de ayuda publicado en la comunidad!'),
          backgroundColor: Color(0xFF2A9D8F),
        ),
      );
      // Cierra el formulario y vuelve al selector o pantalla previa
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HelpFormController>();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const BackButtonIcon(),
          tooltip: 'Volver',
        ),
        title: const Text('Ayuda'),
      ),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        '¿Qué necesitas?',
                        style: textTheme.headlineSmall,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: controller.descriptionController,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      minLines: 3,
                      maxLines: 6,
                      validator: RequiredFieldValidator.validate,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: const InputDecoration(
                        labelText: 'Descripción (Obligatorio)',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    HelpDetailsSection(controller: controller),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Recompensa'),
                      subtitle: Text(controller.rewardEnabled ? 'Sí' : 'No'),
                      value: controller.rewardEnabled,
                      onChanged: controller.setRewardEnabled,
                    ),
                    if (controller.rewardEnabled)
                      TextFormField(
                        controller: controller.rewardController,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: '¿Qué ofreces? (Opcional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    const SizedBox(height: 12),
                    OptionalPhotoPicker(
                      label: 'Agregar foto',
                      photoPath: controller.photoPath,
                      onChanged: controller.setPhotoPath,
                      pickFromCamera: controller.takePhoto,
                      pickFromGallery: controller.choosePhoto,
                    ),
                    const SizedBox(height: 24),
                    FormFooterButtons(onPublish: _publish),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
