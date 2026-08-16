/// Centralized validation rules so signup/login screens stay consistent
/// and the "disable button until valid" behavior is computed the same
/// way everywhere.
class Validators {
  Validators._();

  static final RegExp _emailRegex =
      RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$');

  static final RegExp _upper = RegExp(r'[A-Z]');
  static final RegExp _lower = RegExp(r'[a-z]');
  static final RegExp _digit = RegExp(r'[0-9]');
  static final RegExp _special = RegExp(r'[!@#\$&*~^%()\-_+=\[\]{};:,.<>/?]');

  static String? username(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Enter a username';
    if (v.length < 3) return 'Username must be at least 3 characters';
    return null;
  }

  static String? email(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Enter your email';
    if (!_emailRegex.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  /// Returns null when valid, otherwise the first unmet rule.
  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Enter a password';
    if (v.length < 8) return 'Password must be at least 8 characters';
    if (!_upper.hasMatch(v)) return 'Add at least one uppercase letter';
    if (!_lower.hasMatch(v)) return 'Add at least one lowercase letter';
    if (!_digit.hasMatch(v)) return 'Add at least one number';
    if (!_special.hasMatch(v)) return 'Add at least one special character';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Confirm your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }

  static bool isPasswordStrong(String value) => password(value) == null;
  static bool isEmailValid(String value) => email(value) == null;
  static bool isUsernameValid(String value) => username(value) == null;
}
