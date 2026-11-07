import 'required_field_validator.dart';

abstract final class ServiceAmountValidator {
  static final _amount = RegExp(r'^[0-9]+(?:[.,][0-9]{1,2})?$');

  static bool isValid(String? value) {
    return value != null && _amount.hasMatch(value.trim());
  }

  static String? validate(String? value) {
    if (!RequiredFieldValidator.isValid(value)) {
      return 'Ingresa el monto a cobrar.';
    }
    return isValid(value) ? null : 'Ingresa un monto con hasta dos decimales.';
  }
}
