import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_iii_3d/features/home/screens/home_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('home screen displays user information and allows sign out', (tester) async {
    final testUser = {
      'id': 'uid_teste',
      'email': 'usuario.social@exemplo.com',
      'nome': 'Jefferson Santos',
      'provider': 'google',
    };

    await tester.pumpWidget(MaterialApp(home: HomeScreen(user: testUser)));

    expect(find.text('Olá, Jefferson Santos'), findsOneWidget);
    expect(find.text('usuario.social@exemplo.com'), findsOneWidget);
    expect(find.text('Conectado via GOOGLE'), findsOneWidget);
    expect(find.byIcon(Icons.logout_rounded), findsWidgets);

    // Tap logout button in AppBar (always visible)
    await tester.tap(find.byIcon(Icons.logout_rounded).last);
    await tester.pumpAndSettle();

    // After logout, it redirects to login screen
    expect(find.text('Bem-vindo de volta'), findsOneWidget);
  });
}
