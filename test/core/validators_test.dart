import 'package:flutter_test/flutter_test.dart';
import 'package:surgam_capital/core/utils/validators.dart';

void main() {
  test('username validation rejects empty values', () {
    expect(Validators.requiredUsername(''), 'Username cannot be empty');
  });

  test('password validation rejects empty values', () {
    expect(Validators.requiredPassword(''), 'Password cannot be empty');
  });

  test('OTP validation requires six digits', () {
    expect(Validators.otp('123'), 'OTP must contain exactly six digits');
    expect(Validators.otp('123456'), null);
  });
}
