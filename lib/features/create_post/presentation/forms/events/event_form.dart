import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/validators/required_field_validator.dart';
import '../../../domain/entities/event_post_data.dart';
import '../../submission/post_submission_scope.dart';

class EventForm extends StatefulWidget {
  const EventForm({super.key});

  @override
  State<EventForm> createState() => _EventFormState();
}

class _EventFormState extends State<EventForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _place = TextEditingController();
  final _attendees = TextEditingController();
  final _description = TextEditingController();
  DateTime? _day;
  TimeOfDay? _time;

  DateTime? get _startsAt {
    final day = _day;
    final time = _time;
    if (day == null || time == null) return null;
    return DateTime(day.year, day.month, day.day, time.hour, time.minute);
  }

  Future<void> _pickDay(FormFieldState<DateTime> field) async {
    FocusScope.of(context).unfocus();
    final today = DateUtils.dateOnly(DateTime.now());
    final day = _day;
    final selection = await showDatePicker(
      context: context,
      initialDate: day != null && !day.isBefore(today) ? day : today,
      firstDate: today,
      lastDate: DateTime(today.year + 10, 12, 31),
      helpText: 'Selecciona el día del evento',
    );
    if (!mounted || !field.mounted || selection == null) return;
    setState(() => _day = selection);
    field.didChange(_startsAt);
  }

  Future<void> _pickTime(FormFieldState<DateTime> field) async {
    FocusScope.of(context).unfocus();
    final selection = await showTimePicker(
      context: context,
      initialTime:
          _time ??
          TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1))),
      helpText: 'Selecciona la hora del evento',
    );
    if (!mounted || !field.mounted || selection == null) return;
    setState(() => _time = selection);
    field.didChange(_startsAt);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labels = MaterialLocalizations.of(context);
    final day = _day;
    final time = _time;
    const outline = OutlineInputBorder();
    final dateButtonStyle = OutlinedButton.styleFrom(
      alignment: Alignment.centerLeft,
      minimumSize: const Size(0, 48),
    );

    return PostSubmissionScope(
      formKey: _formKey,
      readData: () => EventPostData(
        title: _title.text,
        place: _place.text,
        startsAt: _startsAt,
        attendees: int.tryParse(_attendees.text),
        description: _description.text,
      ),
      builder: (context, onCancel, footer) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: onCancel,
            icon: const BackButtonIcon(),
            tooltip: 'Volver',
          ),
          title: const Text('Publicar evento'),
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
                    spacing: 16,
                    children: [
                      TextFormField(
                        controller: _title,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.next,
                        validator: RequiredFieldValidator.validate,
                        decoration: const InputDecoration(
                          labelText: 'Título (obligatorio)',
                          border: outline,
                        ),
                      ),
                      TextFormField(
                        controller: _place,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.done,
                        validator: RequiredFieldValidator.validate,
                        decoration: const InputDecoration(
                          labelText: 'Lugar (obligatorio)',
                          border: outline,
                        ),
                      ),
                      FormField<DateTime>(
                        initialValue: _startsAt,
                        autovalidateMode:
                            AutovalidateMode.onUserInteractionIfError,
                        validator: (value) {
                          if (value == null) {
                            return 'Selecciona un día y una hora.';
                          }
                          if (!value.isAfter(DateTime.now())) {
                            return 'El evento debe ser en una fecha y hora futuras.';
                          }
                          return null;
                        },
                        builder: (field) => Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: 8,
                          children: [
                            Text(
                              'Fecha (obligatoria)',
                              style: theme.textTheme.titleMedium,
                            ),
                            OutlinedButton.icon(
                              style: dateButtonStyle,
                              onPressed: () => _pickDay(field),
                              icon: const Icon(Icons.calendar_today_outlined),
                              label: Text(
                                day == null
                                    ? 'Elegir día'
                                    : labels.formatFullDate(day),
                              ),
                            ),
                            OutlinedButton.icon(
                              style: dateButtonStyle,
                              onPressed: () => _pickTime(field),
                              icon: const Icon(Icons.schedule),
                              label: Text(
                                time == null
                                    ? 'Elegir hora'
                                    : labels.formatTimeOfDay(
                                        time,
                                        alwaysUse24HourFormat: true,
                                      ),
                              ),
                            ),
                            if (field.errorText case final error?)
                              Semantics(
                                liveRegion: true,
                                child: Text(
                                  error,
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      TextFormField(
                        controller: _attendees,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) return null;
                          final count = int.tryParse(value);
                          return count == null || count < 0
                              ? 'Ingresa una cantidad válida.'
                              : null;
                        },
                        decoration: const InputDecoration(
                          labelText: 'Asistentes previstos (opcional)',
                          border: outline,
                        ),
                      ),
                      TextFormField(
                        controller: _description,
                        textCapitalization: TextCapitalization.sentences,
                        minLines: 3,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          labelText: 'Detalle (opcional)',
                          alignLabelWithHint: true,
                          border: outline,
                        ),
                      ),
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

  @override
  void dispose() {
    _title.dispose();
    _place.dispose();
    _attendees.dispose();
    _description.dispose();
    super.dispose();
  }
}
