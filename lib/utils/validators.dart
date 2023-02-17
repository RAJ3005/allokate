class Validators {
  static String defaultTextValidator(String input) {
    if (input == null || input == '') return 'This must not be empty';
    return null;
  }

  static String defaultListValidator(int index) {
    if (index == null) return 'You must select an item';
    return null;
  }

  static String defaultNumberValidator(String s) {
    return double.tryParse(s) == null ? 'Input must be a number' : null;
  }
}
