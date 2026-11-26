import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_iii_3d/database/db_helper.dart';
import 'package:mobile_iii_3d/features/clients/screens/clients_screen.dart';
import 'package:mobile_iii_3d/features/finance/screens/finance_screen.dart';
import 'package:mobile_iii_3d/features/pricing/screens/pricing_calculator_screen.dart';
import 'package:mobile_iii_3d/features/settings/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> _pumpUntilLoaded(WidgetTester tester) async {
  for (int i = 0; i < 30; i++) {
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
    await tester.pump();
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
  }
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('ClientsScreen renders and opens new client modal', (tester) async {
    await tester.runAsync(() async => await DbHelper.database);

    await tester.pumpWidget(const MaterialApp(home: ClientsScreen()));
    await _pumpUntilLoaded(tester);

    expect(find.text('Cadastro de Clientes'), findsOneWidget);
    expect(find.text('Novo Cliente'), findsOneWidget);

    await tester.tap(find.text('Novo Cliente'));
    await tester.pumpAndSettle();

    expect(find.text('Cadastrar Novo Cliente'), findsOneWidget);
  });

  testWidgets('PricingCalculatorScreen opens insumo selector modal with options', (tester) async {
    await tester.runAsync(() async => await DbHelper.database);

    await tester.pumpWidget(const MaterialApp(home: PricingCalculatorScreen()));
    await _pumpUntilLoaded(tester);

    expect(find.text('Adicionar Insumo'), findsOneWidget);
    await tester.ensureVisible(find.text('Adicionar Insumo'));
    await tester.tap(find.text('Adicionar Insumo'));
    await tester.pumpAndSettle();

    expect(find.text('Selecionar Insumo / Embalagem'), findsOneWidget);
    expect(find.text('Escolha o Insumo do Estoque'), findsOneWidget);
  });

  testWidgets('SettingsScreen renders general parameters and marketplaces', (tester) async {
    await tester.runAsync(() async => await DbHelper.database);

    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await _pumpUntilLoaded(tester);

    expect(find.text('Configurações & Taxas'), findsOneWidget);
    expect(find.text('Parâmetros Globais de Precificação'), findsOneWidget);
    expect(find.text('Canais de Venda / Marketplaces'), findsOneWidget);
  });

  testWidgets('FinanceScreen renders cash flow and ROI summary', (tester) async {
    await tester.runAsync(() async => await DbHelper.database);

    await tester.pumpWidget(const MaterialApp(home: FinanceScreen()));
    await _pumpUntilLoaded(tester);

    expect(find.text('Financeiro, Caixa & ROI'), findsOneWidget);
    expect(find.text('Payback / ROI das Impressoras'), findsOneWidget);
  });
}
