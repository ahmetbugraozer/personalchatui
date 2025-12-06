import '../../enums/app.enum.dart';

/// Common validation utilities for forms
class Validators {
  static final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  /// Check if email format is valid
  static bool isValidEmail(String email) {
    return _emailRegex.hasMatch(email.trim());
  }

  /// Validate email field
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.authErrorEmailRequired;
    }
    if (!isValidEmail(value)) {
      return AppStrings.authErrorEmailInvalid;
    }
    return null;
  }

  /// Validate password for login (just required)
  static String? loginPassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.authErrorPasswordRequired;
    }
    return null;
  }

  /// Validate password for registration (min 8 chars)
  static String? registerPassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.authErrorPasswordRequired;
    }
    if (value.length < 8) {
      return AppStrings.authErrorPasswordTooShort;
    }
    return null;
  }

  /// Direct validation method - use this in validator callback
  static String? confirmPasswordWith(String? value, String originalPassword) {
    if (value == null || value.isEmpty) {
      return AppStrings.authErrorConfirmPasswordRequired;
    }
    if (value != originalPassword) {
      return AppStrings.authErrorPasswordsNotMatch;
    }
    return null;
  }

  /// Validate confirm password matches original (closure version - deprecated)
  /// Note: This captures the password value at creation time, which may be stale.
  /// Prefer using confirmPasswordWith directly in validator callback.
  @Deprecated('Use confirmPasswordWith instead for real-time validation')
  static String? Function(String?) confirmPassword(String originalPassword) {
    return (String? value) => confirmPasswordWith(value, originalPassword);
  }
}
