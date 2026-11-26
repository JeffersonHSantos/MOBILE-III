import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_iii_3d/database/db_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('DbHelper handles quotes and production workflow', () async {
    // 1. Criar Orçamento
    await DbHelper.insert('vendas', {
      'id': 'orc_teste_1',
      'codigoOrcamento': 'ORC-999',
      'valorTotal': 75.0,
      'statusOrcamento': 'PENDENTE',
      'statusProducao': 'ORCAMENTO',
      'observacoes': 'Teste de orçamento articulado',
    });

    final orc = await DbHelper.getById('vendas', 'orc_teste_1');
    expect(orc, isNotNull);
    expect(orc!['statusOrcamento'], 'PENDENTE');

    // 2. Aprovar Orçamento
    final upOrc = Map<String, dynamic>.from(orc);
    upOrc['statusOrcamento'] = 'APROVADO';
    await DbHelper.update('vendas', upOrc, 'orc_teste_1');

    final orcAprovado = await DbHelper.getById('vendas', 'orc_teste_1');
    expect(orcAprovado!['statusOrcamento'], 'APROVADO');

    // 3. Enviar para produção
    await DbHelper.insert('historico_producao', {
      'id': 'prod_teste_1',
      'vendaId': 'orc_teste_1',
      'produtoId': 'orc_teste_1',
      'impressoraId': 'imp_1',
      'dataProducao': DateTime.now().toIso8601String(),
      'status': 'AGUARDANDO_IMPRESSAO',
      'custoTotalProducao': 75.0,
    });

    final prod = await DbHelper.getById('historico_producao', 'prod_teste_1');
    expect(prod, isNotNull);
    expect(prod!['status'], 'AGUARDANDO_IMPRESSAO');
  });

  test('DbHelper registrarAvaria decreases stock and logs cash flow loss', () async {
    // Criar um filamento com 1000g
    await DbHelper.insert('filamentos', {
      'id': 'fil_avaria_test',
      'marca': 'Bambu Lab',
      'material': 'PLA Basic',
      'corNome': 'Verde Neon',
      'pesoInicialGramas': 1000.0,
      'pesoAtualGramas': 1000.0,
      'precoPago': 120.0,
    });

    // Registrar avaria de 80g
    await DbHelper.registrarAvaria(
      tipoItem: 'FILAMENTO',
      itemId: 'fil_avaria_test',
      itemNome: 'PLA Basic Verde Neon',
      quantidadePerdida: 80.0,
      unidade: 'g',
      custoEstimadoPerda: 9.60,
      motivo: 'Carretel embolou e pausou de madrugada',
    );

    // Verificar se o estoque baixou para 920g
    final filAtualizado = await DbHelper.getById('filamentos', 'fil_avaria_test');
    expect(filAtualizado, isNotNull);
    expect((filAtualizado!['pesoAtualGramas'] as num).toDouble(), 920.0);

    // Verificar se gerou avaria
    final avarias = await DbHelper.getAll('avarias');
    final avariaCriada = avarias.firstWhere((a) => a['itemId'] == 'fil_avaria_test');
    expect(avariaCriada['quantidadePerdida'], 80.0);
    expect(avariaCriada['motivo'], contains('Carretel embolou'));

    // Verificar se gerou movimentação de perda no caixa
    final caixas = await DbHelper.getAll('movimentacoes_caixa');
    final perdaCaixa = caixas.firstWhere((c) => c['referenciaId'] == avariaCriada['id']);
    expect(perdaCaixa['tipo'], 'SAIDA_DESPESA');
    expect(perdaCaixa['valor'], 9.60);
  });

  test('DbHelper exportar e importar JSON', () async {
    final jsonStr = await DbHelper.exportarBancoJson();
    expect(jsonStr, isNotEmpty);
    expect(jsonStr, contains('filamentos'));
    expect(jsonStr, contains('impressoras'));

    expect(() async => await DbHelper.importarBancoJson(jsonStr), returnsNormally);
  });
}
