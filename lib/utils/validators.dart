// Shared client-side validators. Mirrors the backend rules in
// backend/utils/validation.js so users get instant feedback before a round-trip.

final RegExp _emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

bool isValidEmail(String? email) {
  if (email == null) return false;
  final e = email.trim();
  return e.isNotEmpty && e.length <= 254 && _emailRe.hasMatch(e);
}

/// Returns an error message, or null if the password is acceptable.
String? passwordError(String? password) {
  if (password == null || password.length < 8) {
    return 'Password must be at least 8 characters';
  }
  if (!RegExp(r'[A-Za-z]').hasMatch(password) || !RegExp(r'[0-9]').hasMatch(password)) {
    return 'Password must contain a letter and a number';
  }
  return null;
}

/// Returns an error message, or null if a non-negative number.
String? nonNegativeNumberError(String? value, {String field = 'Value'}) {
  if (value == null || value.trim().isEmpty) return '$field is required';
  final n = double.tryParse(value.trim());
  if (n == null) return '$field must be a number';
  if (n < 0) return '$field cannot be negative';
  return null;
}
