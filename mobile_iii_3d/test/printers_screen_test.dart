import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_iii_3d/database/db_helper.dart';
import 'package:mobile_iii_3d/features/printers/screens/printers_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('PrintersScreen renders seeded printers and opens registration modal', (tester) async {
    await tester.runAsync(() async {
      await DbHelper.database;
    });

    await tester.pumpWidget(const MaterialApp(home: PrintersScreen()));
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    expect(find.text('Impressoras 3D & Máquinas'), findsOneWidget);
    expect(find.text('Nova Impressora'), findsOneWidget);
    expect(find.textContaining('Bambu Lab'), findsWidgets);

    await tester.tap(find.text('Nova Impressora'));
    await tester.pumpAndSettle();

    expect(find.text('Cadastrar Nova Impressora 3D'), findsOneWidget);
    expect(find.text('Cadastrar Impressora'), findsOneWidget);
  });
}
