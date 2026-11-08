import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../../features/emergency/data/firebase_emergency_post_repository.dart';
import '../../../../../features/emergency/domain/emergency_type_labels.dart';
import '../../../../../core/constants/input_limits.dart';
import '../../../../../core/constants/photo_limits.dart';
import '../../../../../core/validators/required_field_validator.dart';
import '../../../../../core/widgets/collapsible_section.dart';
import '../../../../../core/widgets/optional_photo_picker.dart';
import '../../../domain/entities/emergency_post_data.dart';
import '../../../domain/services/location_provider.dart';
import '../../../domain/services/photo_picker.dart';
import '../../../domain/services/post_repository.dart';
import '../../location/post_location_capture.dart';
import '../../submission/post_submission_scope.dart';
import 'emergency_form_controller.dart';

class EmergencyForm extends StatelessWidget {
  const EmergencyForm({super.key, this.sosAlertId, this.sosRepository});

  final String? sosAlertId;
  final FirebaseEmergencyPostRepository? sosRepository;

  @override
  Widget build(BuildContext context) {
    final form = ChangeNotifierProvider(
      create: (context) => EmergencyFormController(
        locationProvider: context.read<LocationProvider>(),
        photoPicker: context.read<PhotoPicker>(),
      ),
      child: _EmergencyFormView(sosMode: sosAlertId != null),
    );
    if (sosRepository == null) return form;
    return Provider<PostRepository?>.value(value: sosRepository, child: form);
  }
}

class _EmergencyFormView extends StatefulWidget {
  const _EmergencyFormView({required this.sosMode});

  final bool sosMode;

  @override
  State<_EmergencyFormView> createState() => _EmergencyFormViewState();
}

class _EmergencyFormViewState extends State<_EmergencyFormView> {
  static const _red = Color(0xFFB72F29);
  static const _selectedRed = Color(0xFF8C211D);
  static const _typeRows = [
    [EmergencyType.robbery, EmergencyType.accident],
    [EmergencyType.tragedy, EmergencyType.health],
  ];

  final _formKey = GlobalKey<FormState>();

  Widget _typeButton(EmergencyFormController controller, EmergencyType type) {
    final selected = controller.type == type;
    final label = emergencyTypeLabel(type.name);
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
          title: Text(widget.sosMode ? 'Completar alerta SOS' : 'Emergencia'),
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
                      if (widget.sosMode) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Tu alerta SOS ya está activa. Agrega los detalles '
                            'para compartirlos con tu comunidad.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
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
                                  for (final type in row)
                                    Expanded(
                                      child: _typeButton(controller, type),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (widget.sosMode) ...[
                        TextFormField(
                          controller: controller.titleController,
                          textCapitalization: TextCapitalization.sentences,
                          maxLength: 80,
                          validator: RequiredFieldValidator.validate,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: const InputDecoration(
                            labelText: 'Título (Obligatorio)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
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
