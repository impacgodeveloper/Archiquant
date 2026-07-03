import 'package:archiquant_flutter/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isValidEmail', () {
    test('accepts valid addresses', () {
      expect(isValidEmail('adityaram@impacgo.com'), isTrue);
      expect(isValidEmail('a@b.co'), isTrue);
    });
    test('rejects invalid addresses', () {
      for (final e in ['bad', 'a@b', '@b.com', 'a b@c.com', '', null]) {
        expect(isValidEmail(e), isFalse, reason: 'should reject "$e"');
      }
    });
  });

  group('passwordError', () {
    test('null for acceptable passwords', () {
      expect(passwordError('demo1234'), isNull);
    });
    test('message for weak passwords', () {
      expect(passwordError('ab1'), isNotNull);       // too short
      expect(passwordError('password'), isNotNull);  // no number
      expect(passwordError('12345678'), isNotNull);  // no letter
      expect(passwordError(null), isNotNull);
    });
  });

  group('nonNegativeNumberError', () {
    test('accepts non-negative numbers', () {
      expect(nonNegativeNumberError('0'), isNull);
      expect(nonNegativeNumberError('8.2'), isNull);
    });
    test('rejects negatives / garbage / empty', () {
      expect(nonNegativeNumberError('-1'), isNotNull);
      expect(nonNegativeNumberError('abc'), isNotNull);
      expect(nonNegativeNumberError(''), isNotNull);
    });
  });
}
