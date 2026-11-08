import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/constants/photo_limits.dart';
import '../../../../../core/validators/required_field_validator.dart';
import '../../../../../core/widgets/optional_photo_picker.dart';
import '../../../domain/entities/news_post_data.dart';
import '../../../domain/services/photo_picker.dart';
import '../../submission/post_submission_scope.dart';
import 'news_form_controller.dart';

class NewsForm extends StatelessWidget {
  const NewsForm({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          NewsFormController(photoPicker: context.read<PhotoPicker>()),
      child: const _NewsFormView(),
    );
  }
}

class _NewsFormView extends StatefulWidget {
  const _NewsFormView();

  @override
  State<_NewsFormView> createState() => _NewsFormViewState();
}

class _NewsFormViewState extends State<_NewsFormView> {
  static const _topicLabels = {
    NewsTopic.generalNotice: 'Aviso General',
    NewsTopic.lostPet: 'Mascota Perdida',
    NewsTopic.neighborhoodLife: 'Vida Vecinal',
    NewsTopic.worksOrOutages: 'Obras / Cortes de servicio',
  };

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NewsFormController>();
    final textTheme = Theme.of(context).textTheme;

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
          title: const Text('Noticias'),
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
                      TextFormField(
                        controller: controller.titleController,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.next,
                        validator: RequiredFieldValidator.validate,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: const InputDecoration(
                          labelText: 'Título o Asunto (Obligatorio)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: controller.descriptionController,
                        keyboardType: TextInputType.multiline,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.newline,
                        minLines: 4,
                        maxLines: 8,
                        validator: RequiredFieldValidator.validate,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: const InputDecoration(
                          labelText:
                              '¿Qué está pasando en el barrio? (Obligatorio)',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Semantics(
                        header: true,
                        child: Text(
                          'Categoría rápida (Opcional)',
                          style: textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          for (final entry in _topicLabels.entries)
                            ChoiceChip(
                              label: Text(entry.value),
                              selected: controller.topic == entry.key,
                              onSelected: (selected) => controller.setTopic(
                                selected ? entry.key : null,
                              ),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.padded,
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      OptionalPhotoPicker(
                        label: 'Subir foto',
                        photoPaths: [?controller.photoPath],
                        onChanged: (paths) =>
                            controller.setPhotoPath(paths.firstOrNull),
                        maxPhotos: newsPhotoLimit,
                        pickFromCamera: controller.takePhoto,
                        pickFromGallery: controller.choosePhoto,
                      ),
                      const SizedBox(height: 24),
                      footer,
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
