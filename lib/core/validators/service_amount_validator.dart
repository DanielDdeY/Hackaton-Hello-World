import 'required_field_validator.dart';

abstract final class ServiceAmountValidator {
  static final _amount = RegExp(r'^[0-9]+(?:[.,][0-9]{1,2})?$');

  static bool isValid(String? value) {
    return parse(value) != null;
  }

  static num? parse(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (!_amount.hasMatch(trimmed)) return null;
    final parsed = num.tryParse(trimmed.replaceAll(',', '.'));
    return parsed != null && parsed.isFinite ? parsed : null;
  }

  static String? validate(String? value) {
    if (!RequiredFieldValidator.isValid(value)) {
      return 'Ingresa el monto a cobrar.';
    }
    return isValid(value) ? null : 'Ingresa un monto con hasta dos decimales.';
  }
}
