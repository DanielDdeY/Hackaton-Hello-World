import 'package:flutter/material.dart';

import '../../../domain/entities/service_availability.dart';
import '../../../domain/entities/service_post_data.dart';
import '../../../domain/services/photo_picker.dart';

class ServiceFormController extends ChangeNotifier {
  ServiceFormController({required this._photoPicker});

  final PhotoPicker _photoPicker;
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final amountController = TextEditingController();
  final phoneController = TextEditingController();
  final stockController = TextEditingController();

  ServiceMode _mode = ServiceMode.provideService;
  Set<PaymentMethod> _paymentMethods = const {};
  Set<Weekday> _days = const {};
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String? _attachmentPath;

  ServiceMode get mode => _mode;
  Set<PaymentMethod> get paymentMethods => _paymentMethods;
  Set<Weekday> get days => _days;
  TimeOfDay? get startTime => _startTime;
  TimeOfDay? get endTime => _endTime;
  String? get attachmentPath => _attachmentPath;

  void setMode(ServiceMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
  }

  void setPaymentMethods(Set<PaymentMethod> methods) {
    _paymentMethods = Set.unmodifiable(methods);
    notifyListeners();
  }

  void toggleDay(Weekday day) {
    final days = {..._days};
    if (!days.remove(day)) days.add(day);
    _days = Set.unmodifiable(days);
    notifyListeners();
  }

  void setStartTime(TimeOfDay time) {
    _startTime = time;
    notifyListeners();
  }

  void setEndTime(TimeOfDay time) {
    _endTime = time;
    notifyListeners();
  }

  void clearAvailability() {
    _days = const {};
    _startTime = null;
    _endTime = null;
    notifyListeners();
  }

  Future<String?> chooseAttachment() => _photoPicker.pickFromGallery();

  void setAttachmentPath(String? path) {
    _attachmentPath = path;
    notifyListeners();
  }

  ServiceAvailability? get availability {
    if (_days.isEmpty && _startTime == null && _endTime == null) return null;

    return ServiceAvailability(
      days: _days,
      startMinute: _minutesOfDay(_startTime),
      endMinute: _minutesOfDay(_endTime),
    );
  }

  ServicePostData get data => ServicePostData(
    title: titleController.text.trim(),
    description: descriptionController.text.trim(),
    amount: amountController.text.trim(),
    phoneNumber: phoneController.text,
    mode: _mode,
    paymentMethods: _paymentMethods,
    availability: availability,
    stock: int.tryParse(stockController.text, radix: 10),
    attachmentPath: _attachmentPath,
  );

  static int? _minutesOfDay(TimeOfDay? time) {
    return time == null
        ? null
        : time.hour * Duration.minutesPerHour + time.minute;
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    amountController.dispose();
    phoneController.dispose();
    stockController.dispose();
    super.dispose();
  }
}
