class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(value)) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Must contain an uppercase letter';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Must contain a number';
    return null;
  }

  static String? required(String? value, [String field = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? coinAmount(String? value, {int min = 10, int? max, int? balance}) {
    if (value == null || value.isEmpty) return 'Amount is required';
    final amount = int.tryParse(value);
    if (amount == null) return 'Enter a valid number';
    if (amount < min) return 'Minimum amount is $min AXC';
    if (max != null && amount > max) return 'Maximum amount is $max AXC';
    if (balance != null && amount > balance) return 'Insufficient balance';
    return null;
  }

  static String? productPrice(String? value) {
    if (value == null || value.isEmpty) return 'Price is required';
    final price = int.tryParse(value);
    if (price == null || price <= 0) return 'Enter a valid price';
    if (price < 1) return 'Minimum price is 1 AXC';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) return null; // optional
    if (!RegExp(r'^\+?[1-9]\d{6,14}$').hasMatch(value.replaceAll(' ', ''))) {
      return 'Enter a valid phone number';
    }
    return null;
  }
}
