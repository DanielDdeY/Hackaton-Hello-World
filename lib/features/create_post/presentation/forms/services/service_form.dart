import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../../core/constants/input_limits.dart';
import '../../../../../core/validators/peruvian_phone_validator.dart';
import '../../../../../core/validators/required_field_validator.dart';
import '../../../../../core/validators/service_amount_validator.dart';
import '../../../../../core/validators/service_stock_validator.dart';
import '../../../../../core/widgets/dashed_action_box.dart';
import '../../../../../core/widgets/optional_photo_picker.dart';
import '../../../domain/entities/service_post_data.dart';
import '../../../domain/services/photo_picker.dart';
import '../../../domain/services/service_category_classifier.dart';
import '../../submission/post_submission_scope.dart';
import '../../widgets/payment_methods_sheet.dart';
import 'service_availability_fields.dart';
import 'service_form_controller.dart';

class ServiceForm extends StatelessWidget {
  const ServiceForm({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ServiceFormController(
        photoPicker: context.read<PhotoPicker>(),
        classifier: context.read<ServiceCategoryClassifier>(),
      ),
      child: const _ServiceFormView(),
    );
  }
}

class _ServiceFormView extends StatefulWidget {
  const _ServiceFormView();

  @override
  State<_ServiceFormView> createState() => _ServiceFormViewState();
}

class _ServiceFormViewState extends State<_ServiceFormView> {
  final _formKey = GlobalKey<FormState>();

  Future<void> _openPaymentMethods(ServiceFormController controller) async {
    FocusScope.of(context).unfocus();
    final selection = await showModalBottomSheet<Set<PaymentMethod>>(
      context: context,
      barrierLabel: 'Cerrar medios de pago',
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) =>
          PaymentMethodsSheet(initialSelection: controller.paymentMethods),
    );
    if (mounted && selection != null) controller.setPaymentMethods(selection);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ServiceFormController>();
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
          title: const Text('Servicios'),
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
                          '¿Qué servicio brindas?',
                          style: textTheme.headlineSmall,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: controller.titleController,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.next,
                        validator: RequiredFieldValidator.validate,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: const InputDecoration(
                          labelText: 'Título (Obligatorio)',
                          hintText: 'Ej. Gasfitero profesional',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: controller.descriptionController,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        minLines: 3,
                        maxLines: 6,
                        validator: RequiredFieldValidator.validate,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: const InputDecoration(
                          labelText: 'Información (Obligatorio)',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Modalidad (Obligatorio)',
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<ServiceMode>(
                        expandedInsets: EdgeInsets.zero,
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: ServiceMode.provideService,
                            label: Text(
                              'Brindar Servicio',
                              textAlign: TextAlign.center,
                            ),
                          ),
                          ButtonSegment(
                            value: ServiceMode.sell,
                            label: Text('Vender', textAlign: TextAlign.center),
                          ),
                        ],
                        selected: {controller.mode},
                        onSelectionChanged: (selection) =>
                            controller.setMode(selection.single),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: controller.amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                        validator: ServiceAmountValidator.validate,
                        autovalidateMode:
                            AutovalidateMode.onUserInteractionIfError,
                        decoration: const InputDecoration(
                          labelText: 'Monto a cobrar (Obligatorio)',
                          prefixText: 'S/ ',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DashedActionBox(
                        label: 'Medio de pago',
                        icon: Icons.add,
                        onTap: () => _openPaymentMethods(controller),
                      ),
                      if (controller.paymentMethods.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              for (final method in PaymentMethod.values)
                                if (controller.paymentMethods.contains(method))
                                  Chip(label: Text(method.label)),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: controller.phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(
                            peruvianMobileLength,
                          ),
                        ],
                        validator: PeruvianPhoneValidator.validate,
                        autovalidateMode:
                            AutovalidateMode.onUserInteractionIfError,
                        decoration: const InputDecoration(
                          labelText: 'Número (Obligatorio)',
                          hintText: 'Celular peruano de 9 dígitos',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        layoutBuilder: (currentChild, previousChildren) =>
                            Stack(
                              alignment: Alignment.topCenter,
                              children: [
                                for (final child in previousChildren)
                                  ExcludeSemantics(
                                    child: ExcludeFocus(
                                      child: IgnorePointer(child: child),
                                    ),
                                  ),
                                ?currentChild,
                              ],
                            ),
                        child: controller.mode == ServiceMode.sell
                            ? TextFormField(
                                key: const ValueKey(ServiceMode.sell),
                                controller: controller.stockController,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.done,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (value) =>
                                    controller.mode == ServiceMode.sell
                                    ? ServiceStockValidator.validate(value)
                                    : null,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteractionIfError,
                                decoration: const InputDecoration(
                                  labelText: 'Cantidad / Stock (Obligatorio)',
                                  border: OutlineInputBorder(),
                                ),
                              )
                            : ServiceAvailabilityFields(
                                key: const ValueKey(ServiceMode.provideService),
                                controller: controller,
                              ),
                      ),
                      const SizedBox(height: 16),
                      OptionalPhotoPicker(
                        label: 'Agregar certificados o Fotos',
                        photoPaths: [?controller.attachmentPath],
                        onChanged: (paths) =>
                            controller.setAttachmentPath(paths.firstOrNull),
                        pickFromGallery: controller.chooseAttachment,
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
