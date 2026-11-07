import '../../../../core/validators/peruvian_phone_validator.dart';
import '../../../../core/validators/required_field_validator.dart';
import '../../../../core/validators/service_amount_validator.dart';
import 'post_category.dart';
import 'post_form_data.dart';
import 'service_availability.dart';

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
}
