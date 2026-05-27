class Validators {
  Validators._();

  static String? requiredText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio.';
    }

    return null;
  }

  static String? positiveNumber(String? value) {
    final parsed = double.tryParse(value?.trim() ?? '');

    if (parsed == null || parsed <= 0) {
      return 'Ingresa un número válido.';
    }

    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty || !text.contains('@')) {
      return 'Ingresa un correo válido.';
    }

    return null;
  }
}
