import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/constants/photo_limits.dart';
import '../../../../../core/validators/required_field_validator.dart';
import '../../../../../core/widgets/form_footer_buttons.dart';
import '../../../../../core/widgets/optional_photo_picker.dart';
import '../../../domain/services/photo_picker.dart';
import 'help_details_section.dart';
import '../../auth/ensure_post_author.dart';
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

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    final data = context.read<HelpFormController>().data;
    if (!await ensurePostAuthor(context) || !mounted) return;

    if (kDebugMode) {
      final payload = {
        'description': data.description,
        'neededBy': data.neededBy?.toIso8601String().split('T').first,
        'peopleCount': data.peopleCount,
        'location': data.location,
        'reward': data.reward,
        'photoPath': data.photoPath,
      };
      debugPrint('Help post: ${jsonEncode(payload)}');
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
                      photoPaths: [?controller.photoPath],
                      onChanged: (paths) =>
                          controller.setPhotoPath(paths.firstOrNull),
                      maxPhotos: helpPhotoLimit,
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
