import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_iii_3d/database/db_helper.dart';
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

  test('upsertSocialUser and query work without throwing errors', () async {
    await DbHelper.upsertSocialUser(
      email: 'social_tester@teste.com',
      name: 'Social Tester',
      provider: 'google',
      firebaseUid: 'uid_123456',
    );

    final loggedUser = await DbHelper.login('social_tester@teste.com', 'uid_123456');
    expect(loggedUser, isNotNull);
    expect(loggedUser!['nome'], 'Social Tester');
    expect(loggedUser['provider'], 'google');
  });

  test('signOut executes without exceptions', () async {
    expect(() async => await AuthService.signOut(), returnsNormally);
  });
}
