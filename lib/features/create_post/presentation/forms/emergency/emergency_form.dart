import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../../core/constants/input_limits.dart';
import '../../../../../core/constants/photo_limits.dart';
import '../../../../../core/validators/required_field_validator.dart';
import '../../../../../core/widgets/collapsible_section.dart';
import '../../../../../core/widgets/optional_photo_picker.dart';
import '../../../domain/entities/emergency_post_data.dart';
import '../../../domain/services/location_provider.dart';
import '../../../domain/services/photo_picker.dart';
import '../../location/post_location_capture.dart';
import '../../submission/post_submission_scope.dart';
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
  static const _red = Color(0xFFB72F29);
  static const _selectedRed = Color(0xFF8C211D);
  static const _typeRows = [
    [(EmergencyType.robbery, 'ROBO'), (EmergencyType.accident, 'ACCIDENTE')],
    [(EmergencyType.tragedy, 'TRAGEDIA'), (EmergencyType.health, 'SALUD')],
  ];

  final _formKey = GlobalKey<FormState>();

  Widget _typeButton(
    EmergencyFormController controller,
    EmergencyType type,
    String label,
  ) {
    final selected = controller.type == type;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: FilledButton(
        onPressed: () => controller.selectType(type),
        style: FilledButton.styleFrom(
          backgroundColor: selected ? _selectedRed : _red,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 72),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (selected) ...[
              const Icon(Icons.check, size: 18),
              const SizedBox(width: 6),
            ],
            Flexible(child: Text(label, textAlign: TextAlign.center)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<EmergencyFormController>();
    final theme = Theme.of(context);
    final locationNotice = controller.locationNotice;
    final publishStyle =
        (FilledButtonTheme.of(context).style ?? const ButtonStyle()).merge(
          FilledButton.styleFrom(
            backgroundColor: _red,
            foregroundColor: Colors.white,
          ),
        );

    return PostSubmissionScope(
      formKey: _formKey,
      readData: () => controller.data,
      builder: (context, onCancel, footer) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: onCancel,
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
                      Column(
                        spacing: 12,
                        children: [
                          for (final row in _typeRows)
                            IntrinsicHeight(
                              child: Row(
                                spacing: 12,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (final (type, label) in row)
                                    Expanded(
                                      child: _typeButton(
                                        controller,
                                        type,
                                        label,
                                      ),
                                    ),
                                ],
                              ),
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
                                  PostLocationStatus.loading
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
                      if (locationNotice != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Semantics(
                            liveRegion: true,
                            child: Text(
                              locationNotice,
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
                        photoPaths: [?controller.photoPath],
                        onChanged: (paths) =>
                            controller.setPhotoPath(paths.firstOrNull),
                        maxPhotos: emergencyPhotoLimit,
                        pickFromCamera: controller.takePhoto,
                      ),
                      const SizedBox(height: 24),
                      FilledButtonTheme(
                        data: FilledButtonThemeData(style: publishStyle),
                        child: footer,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
