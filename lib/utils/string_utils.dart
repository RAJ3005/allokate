import 'package:intl/intl.dart';

class StringUtils {
  static bool isNullOrEmpty(String string) {
    return string == null || string.isEmpty || string == ' ';
  }

  static String formatMoney(var input, {int decimalPlaces = 2}) {
    if (input == null) return '';
    double money;
    if (input is String) {
      money = double.parse(input);
    } else {
      money = input.toDouble();
    }
    final formatCurrency = NumberFormat.currency(
        locale: 'en_GB', symbol: '£', decimalDigits: decimalPlaces);
    return formatCurrency.format(money);
  }

  static String formatUpTo2DecimalPlaces(double v) {
    if (v == null) return '';

    NumberFormat formatter = NumberFormat();
    formatter.minimumFractionDigits = 0;
    formatter.maximumFractionDigits = 2;
    formatter.turnOffGrouping();
    return formatter.format(v);
  }

  static String formatMoneyForInterval(num input, num interval) {
    input = input.toDouble();
    interval = interval.toDouble();

    if (interval < 100) {
      input = (input / 10).round() * 10;
    } else if (interval < 1000) {
      input = (input / 100).round() * 100;
    } else if (interval < 1000 * 1000) // 1 million
    {
      input = (input / 1000).round() * 1000;
      return '£' + (input / 1000).round().toString() + 'k';
    } else if (interval < 1000 * 1000 * 1000) // 1 billion
    {
      input = (input / (1000 * 1000)).round() * (1000 * 1000);
      return '£' + (input / (1000 * 1000)).round().toString() + 'm';
    } else if (interval < 1000 * 1000 * 1000 * 1000) // 1 trillion
    {
      input = (input / (1000 * 1000 * 1000)).round() * (1000 * 1000 * 1000);
      return '£' + (input / (1000 * 1000 * 1000)).round().toString() + 'b';
    }

    return formatMoney(input, decimalPlaces: 0);
  }

  static const String alphabetUpper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String alphabetLower = 'abcdefghijklmnopqrstuvwxyz';

  static String formatEnumString(String s) {
    return s.split('.').sublist(1).join();
  }

  static String capitalise(String string) =>
      '${string[0].toUpperCase()}${string.substring(1)}';
}
