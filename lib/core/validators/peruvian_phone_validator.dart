import '../constants/input_limits.dart';
import 'required_field_validator.dart';

abstract final class PeruvianPhoneValidator {
  static final _mobileNumber = RegExp(r'^9[0-9]*$');

  static bool isValid(String? value) {
    return value != null &&
        value.length == peruvianMobileLength &&
        _mobileNumber.hasMatch(value);
  }

  static String? validate(String? value) {
    if (!RequiredFieldValidator.isValid(value)) {
      return 'Ingresa un número de celular.';
    }
    return isValid(value) ? null : 'Ingresa 9 dígitos que empiecen con 9.';
  }
}
