class MoneyFormatter {
  MoneyFormatter._();

  static String formatBob(num value) {
    return '${value.toStringAsFixed(0)} Bs';
  }
}
