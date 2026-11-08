import '../../../../core/validators/peruvian_phone_validator.dart';
import '../../../../core/validators/required_field_validator.dart';
import '../../../../core/validators/service_amount_validator.dart';
import 'post_category.dart';
import 'post_form_data.dart';
import 'post_location.dart';
import 'service_availability.dart';
import 'service_category.dart';

enum ServiceMode { provideService, sell }

enum PaymentMethod {
  yape,
  plin,
  cash,
  bcpTransfer,
  interbankTransfer,
  bbvaTransfer,
  scotiabankTransfer,
  card,
}

final class ServicePostData implements PostFormData {
  ServicePostData({
    required this.title,
    required this.description,
    required this.amount,
    required this.phoneNumber,
    this.mode = ServiceMode.provideService,
    Set<PaymentMethod> paymentMethods = const {},
    ServiceAvailability? availability,
    int? stock,
    this.attachmentPath,
    this.locationData,
    this.serviceCategory = ServiceCategory.other,
  }) : paymentMethods = Set.unmodifiable(paymentMethods),
       availability = mode == ServiceMode.provideService ? availability : null,
       stock = mode == ServiceMode.sell ? stock : null;

  final String title;
  final String description;
  final String amount;
  final String phoneNumber;
  final ServiceMode mode;
  final Set<PaymentMethod> paymentMethods;
  final ServiceAvailability? availability;
  final int? stock;
  final String? attachmentPath;
  final ServiceCategory serviceCategory;
  @override
  final PostLocation? locationData;

  @override
  List<String> get localPhotoPaths => [?attachmentPath];

  @override
  PostCategory get category => PostCategory.services;

  @override
  bool get isValid {
    if (!RequiredFieldValidator.isValid(title) ||
        !RequiredFieldValidator.isValid(description) ||
        !ServiceAmountValidator.isValid(amount) ||
        !PeruvianPhoneValidator.isValid(phoneNumber)) {
      return false;
    }

    return switch (mode) {
      ServiceMode.provideService => availability?.isValid ?? true,
      ServiceMode.sell => (stock ?? 0) >= 1,
    };
  }

  @override
  Map<String, Object?> toMap() {
    final banks = [for (final method in paymentMethods) ?_bankNames[method]];
    return {
      'title': title,
      'information': description,
      'serviceCategory': serviceCategory.key,
      'categorySource': 'keyword',
      'mode': mode == ServiceMode.sell ? 'sell' : 'provide_service',
      'price': ServiceAmountValidator.parse(amount),
      'currency': 'PEN',
      'paymentMethods': [
        for (final method in paymentMethods)
          if (!_bankNames.containsKey(method)) method.name,
        if (banks.isNotEmpty) 'bank_transfer',
      ],
      if (banks.isNotEmpty) 'transferBanks': banks,
      'contactPhone': phoneNumber,
      if (availability case final hours?)
        'availability': {
          'days': [for (final day in hours.days) day.name.substring(0, 3)],
          'startTime': _formatMinutes(hours.startMinute),
          'endTime': _formatMinutes(hours.endMinute),
        },
      if (mode == ServiceMode.sell) 'stock': stock,
    };
  }

  static const _bankNames = {
    PaymentMethod.bcpTransfer: 'bcp',
    PaymentMethod.interbankTransfer: 'interbank',
    PaymentMethod.bbvaTransfer: 'bbva',
    PaymentMethod.scotiabankTransfer: 'scotiabank',
  };

  static String? _formatMinutes(int? minutes) {
    if (minutes == null) return null;
    final hour = (minutes ~/ 60).toString().padLeft(2, '0');
    final minute = (minutes % 60).toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
