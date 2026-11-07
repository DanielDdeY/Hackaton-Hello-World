import 'required_field_validator.dart';

abstract final class ServiceStockValidator {
  static String? validate(String? value) {
    if (!RequiredFieldValidator.isValid(value)) return 'Ingresa la cantidad.';

    final stock = int.tryParse(value!.trim(), radix: 10);
    return stock != null && stock >= 1
        ? null
        : 'Ingresa un número entero de al menos 1.';
  }
}
