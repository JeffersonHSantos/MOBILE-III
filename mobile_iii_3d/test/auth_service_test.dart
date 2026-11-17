import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_iii_3d/services/auth_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('email login succeeds with local database demo user', () async {
    final result = await AuthService.signInWithEmailPassword(
      'admin@teste.com',
      '123456',
    );

    expect(result, isNotNull);
    expect(result!['email'], 'admin@teste.com');
    expect(result['provider'], 'local');
  });

  test('email login fails with invalid credentials', () async {
    final result = await AuthService.signInWithEmailPassword(
      'admin@teste.com',
      'senha_errada',
    );

    expect(result, isNull);
  });
}
