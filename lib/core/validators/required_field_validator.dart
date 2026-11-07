abstract final class RequiredFieldValidator {
  static bool isValid(String? value) => value?.trim().isNotEmpty ?? false;

  static String? validate(String? value) {
    return isValid(value) ? null : 'Este campo es obligatorio.';
  }
}
