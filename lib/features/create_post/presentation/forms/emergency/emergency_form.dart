import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../../core/constants/input_limits.dart';
import '../../../../../core/validators/required_field_validator.dart';
import '../../../../../core/widgets/collapsible_section.dart';
import '../../../../../core/widgets/form_footer_buttons.dart';
import '../../../../../core/widgets/optional_photo_picker.dart';
import '../../../domain/entities/emergency_post_data.dart';
import '../../../domain/services/location_provider.dart';
import '../../../domain/services/photo_picker.dart';
import 'emergency_form_controller.dart';

class EmergencyForm extends StatelessWidget {
  const EmergencyForm({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => EmergencyFormController(
        locationProvider: context.read<LocationProvider>(),
        photoPicker: context.read<PhotoPicker>(),
      ),
      child: const _EmergencyFormView(),
    );
  }
}

class _EmergencyFormView extends StatefulWidget {
  const _EmergencyFormView();

  @override
  State<_EmergencyFormView> createState() => _EmergencyFormViewState();
}

class _EmergencyFormViewState extends State<_EmergencyFormView> {
  static const _typeLabels = {
    EmergencyType.robbery: 'ROBO',
    EmergencyType.accident: 'ACCIDENTE',
    EmergencyType.tragedy: 'TRAGEDIA',
    EmergencyType.health: 'SALUD',
  };

  final _formKey = GlobalKey<FormState>();

  void _publish() {
    if (!_formKey.currentState!.validate()) return;

    if (kDebugMode) {
      final data = context.read<EmergencyFormController>().data;
      debugPrint(
        'Emergency post: ${jsonEncode({'type': data.type.name, 'streetAddress': data.streetAddress, 'message': data.message, 'photoPath': data.photoPath})}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<EmergencyFormController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const BackButtonIcon(),
          tooltip: 'Volver',
        ),
        title: const Text('Emergencia'),
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
                        'Tipo de emergencia (Obligatorio)',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final entry in _typeLabels.entries)
                          ChoiceChip(
                            label: Text(entry.value),
                            selected: controller.type == entry.key,
                            onSelected: (_) => controller.selectType(entry.key),
                            materialTapTargetSize: MaterialTapTargetSize.padded,
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: controller.streetAddressController,
                      onChanged: controller.markAddressEdited,
                      keyboardType: TextInputType.streetAddress,
                      textInputAction: TextInputAction.done,
                      validator: RequiredFieldValidator.validate,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: InputDecoration(
                        labelText: 'CALLE (Obligatorio)',
                        border: const OutlineInputBorder(),
                        suffixIcon:
                            controller.locationStatus ==
                                EmergencyLocationStatus.loading
                            ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    semanticsLabel: 'Obteniendo ubicación',
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                    if (controller.locationStatus ==
                        EmergencyLocationStatus.unavailable)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            'No se pudo obtener tu ubicación, escríbela manualmente',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    CollapsibleSection(
                      label: 'Mensaje',
                      icon: Icons.notes_outlined,
                      expanded: controller.messageExpanded,
                      onChanged: controller.setMessageExpanded,
                      child: TextFormField(
                        controller: controller.messageController,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        minLines: 3,
                        maxLines: 5,
                        maxLength: emergencyMessageMaxLength,
                        maxLengthEnforcement: MaxLengthEnforcement.enforced,
                        decoration: const InputDecoration(
                          labelText: 'Mensaje (Opcional)',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OptionalPhotoPicker(
                      label: 'Tomar Foto',
                      photoPath: controller.photoPath,
                      onChanged: controller.setPhotoPath,
                      pickFromCamera: controller.takePhoto,
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
