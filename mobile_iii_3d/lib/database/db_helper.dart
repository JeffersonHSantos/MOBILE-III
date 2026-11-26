import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class DbHelper {
  static Database? _db;
  static const _uuid = Uuid();
  static const String _webStorageKey = 'mobile_iii_3d_erp_db_v3';
  static bool _webInitialized = false;

  // ==========================================
  // ARMAZENAMENTO EM MEMÓRIA PARA WEB (OFFLINE / DEV)
  // ==========================================
  static final Map<String, List<Map<String, dynamic>>> _webStore = {
    'usuarios': [
      {
        'id': 1,
        'email': 'admin@teste.com',
        'senha': '123456',
        'nome': 'Administrador',
        'provider': 'local',
      }
    ],
    'configuracoes_gerais': [
      {
        'id': 'config_default',
        'valorKwh': 0.95,
        'valorHoraMaoDeObra': 25.0,
        'taxaFalhaPadraoPercentual': 10.0,
        'margemLucroPadraoPercentual': 100.0,
        'taxaImpostoPercentual': 6.0,
      }
    ],
    'impressoras': [
      {
        'id': 'imp_1',
        'nome': 'Bambu Lab A1 Combo (AMS)',
        'potenciaWatts': 160,
        'valorAquisicao': 3800.0,
        'vidaUtilHoras': 4000,
        'custoManutencaoHora': 0.85,
        'fornecedorOndeComprou': 'Revenda Oficial',
        'linkCompra': '',
        'observacoes': 'Equipada com AMS de 4 cores.',
      },
      {
        'id': 'imp_2',
        'nome': 'Creality Ender 3 V3 SE',
        'potenciaWatts': 120,
        'valorAquisicao': 1400.0,
        'vidaUtilHoras': 3000,
        'custoManutencaoHora': 0.60,
        'fornecedorOndeComprou': 'Amazon',
        'linkCompra': '',
        'observacoes': 'Uso geral monocolor.',
      }
    ],
    'filamentos': [
      {
        'id': 'fil_1',
        'marca': 'Bambu Lab',
        'material': 'PLA Basic',
        'corNome': 'Preto',
        'corHex': '#111827',
        'pesoInicialGramas': 1000.0,
        'pesoAtualGramas': 850.0,
        'precoPago': 120.0,
        'codigoBarrasEan': '789100000001',
        'alertaEstoqueMinimoGramas': 150.0,
        'fornecedorOndeComprou': 'Bambu Store',
        'linkCompra': '',
        'observacoes': 'Excelente acabamento.',
      },
      {
        'id': 'fil_2',
        'marca': 'Bambu Lab',
        'material': 'PLA Basic',
        'corNome': 'Branco Jade',
        'corHex': '#F3F4F6',
        'pesoInicialGramas': 1000.0,
        'pesoAtualGramas': 920.0,
        'precoPago': 120.0,
        'codigoBarrasEan': '789100000002',
        'alertaEstoqueMinimoGramas': 150.0,
        'fornecedorOndeComprou': 'Bambu Store',
        'linkCompra': '',
        'observacoes': '',
      },
      {
        'id': 'fil_3',
        'marca': 'Elegoo',
        'material': 'PLA Rapid',
        'corNome': 'Vermelho Fogo',
        'corHex': '#EF4444',
        'pesoInicialGramas': 1000.0,
        'pesoAtualGramas': 600.0,
        'precoPago': 95.0,
        'codigoBarrasEan': '789100000003',
        'alertaEstoqueMinimoGramas': 150.0,
        'fornecedorOndeComprou': 'Mercado Livre',
        'linkCompra': '',
        'observacoes': '',
      },
      {
        'id': 'fil_4',
        'marca': 'Voolt3D',
        'material': 'PETG',
        'corNome': 'Azul Cobalto',
        'corHex': '#2563EB',
        'pesoInicialGramas': 1000.0,
        'pesoAtualGramas': 750.0,
        'precoPago': 105.0,
        'codigoBarrasEan': '789100000004',
        'alertaEstoqueMinimoGramas': 150.0,
        'fornecedorOndeComprou': 'Shopee',
        'linkCompra': '',
        'observacoes': '',
      }
    ],
    'insumos': [
      {
        'id': 'ins_1',
        'nome': 'Argola de Chaveiro com Corrente 25mm',
        'categoria': 'ACESSORIO',
        'quantidadeComprada': 100,
        'quantidadeAtual': 88,
        'precoPacotePago': 25.0,
        'codigoBarrasEan': '',
        'fornecedorOndeComprou': 'Shopee',
        'linkCompra': '',
        'observacoes': '',
      },
      {
        'id': 'ins_2',
        'nome': 'Ímã Neodímio 8x2mm',
        'categoria': 'ACESSORIO',
        'quantidadeComprada': 50,
        'quantidadeAtual': 42,
        'precoPacotePago': 35.0,
        'codigoBarrasEan': '',
        'fornecedorOndeComprou': 'Mercado Livre',
        'linkCompra': '',
        'observacoes': '',
      },
      {
        'id': 'ins_3',
        'nome': 'Caixinha Kraft P (10x10x5cm)',
        'categoria': 'EMBALAGEM',
        'quantidadeComprada': 50,
        'quantidadeAtual': 35,
        'precoPacotePago': 60.0,
        'codigoBarrasEan': '',
        'fornecedorOndeComprou': 'Embalagens Brasil',
        'linkCompra': '',
        'observacoes': '',
      }
    ],
    'canais_venda': [
      {
        'id': 'canal_1',
        'nome': 'Venda Direta / Pix',
        'comissaoPercentual': 0.0,
        'taxaFixaPorVenda': 0.0,
        'taxaAntecipacaoPercentual': 0.0,
      },
      {
        'id': 'canal_2',
        'nome': 'Shopee',
        'comissaoPercentual': 14.0,
        'taxaFixaPorVenda': 4.0,
        'taxaAntecipacaoPercentual': 0.0,
      },
      {
        'id': 'canal_3',
        'nome': 'Mercado Livre',
        'comissaoPercentual': 16.0,
        'taxaFixaPorVenda': 6.0,
        'taxaAntecipacaoPercentual': 0.0,
      }
    ],
    'formas_pagamento': [
      {'id': 'fp_1', 'nome': 'Pix', 'taxaPercentual': 0.0, 'diasParaCair': 0},
      {'id': 'fp_2', 'nome': 'Cartão Crédito 1x', 'taxaPercentual': 3.5, 'diasParaCair': 30},
      {'id': 'fp_3', 'nome': 'Dinheiro em Espécie', 'taxaPercentual': 0.0, 'diasParaCair': 0},
    ],
    'clientes': [
      {
        'id': 'cli_1',
        'nome': 'Cliente Demonstração',
        'telefoneWhatsapp': '(54) 99999-8888',
        'email': 'cliente@exemplo.com',
        'cpfCnpj': '000.000.000-00',
        'cidade': 'Passo Fundo',
        'estado': 'RS',
        'observacoes': 'Cliente frequente.',
      }
    ],
    'produtos': [],
    'produto_filamentos': [],
    'produto_insumos': [],
    'vendas': [],
    'venda_itens': [],
    'historico_producao': [],
    'movimentacoes_caixa': [],
    'avarias': [],
  };

  // ==========================================
  // INICIALIZAÇÃO NATIVA (SQLITE)
  // ==========================================
  static Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError(
        'SQLite nativo não está disponível no navegador. Use os métodos do DbHelper.',
      );
    }

    if (_db != null) return _db!;

    final path = join(await getDatabasesPath(), 'app_faculdade_v3.db');

    _db = await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    await ensureDemoUser();
    return _db!;
  }

  static Future<void> _onCreate(Database db, int version) async {
    // 1. Usuários
    await db.execute('''
      CREATE TABLE IF NOT EXISTS usuarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        senha TEXT NOT NULL,
        nome TEXT,
        provider TEXT DEFAULT 'local'
      )
    ''');

    // 2. Configurações Gerais
    await db.execute('''
      CREATE TABLE IF NOT EXISTS configuracoes_gerais (
        id TEXT PRIMARY KEY,
        valorKwh REAL,
        valorHoraMaoDeObra REAL,
        taxaFalhaPadraoPercentual REAL,
        margemLucroPadraoPercentual REAL,
        taxaImpostoPercentual REAL
      )
    ''');

    // 3. Impressoras
    await db.execute('''
      CREATE TABLE IF NOT EXISTS impressoras (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        potenciaWatts INTEGER,
        valorAquisicao REAL,
        vidaUtilHoras INTEGER,
        custoManutencaoHora REAL,
        fornecedorOndeComprou TEXT,
        linkCompra TEXT,
        observacoes TEXT
      )
    ''');

    // 4. Filamentos
    await db.execute('''
      CREATE TABLE IF NOT EXISTS filamentos (
        id TEXT PRIMARY KEY,
        marca TEXT NOT NULL,
        material TEXT NOT NULL,
        corNome TEXT NOT NULL,
        corHex TEXT,
        pesoInicialGramas REAL,
        pesoAtualGramas REAL,
        precoPago REAL,
        codigoBarrasEan TEXT,
        alertaEstoqueMinimoGramas REAL,
        fornecedorOndeComprou TEXT,
        linkCompra TEXT,
        observacoes TEXT
      )
    ''');

    // 5. Insumos
    await db.execute('''
      CREATE TABLE IF NOT EXISTS insumos (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        categoria TEXT NOT NULL,
        quantidadeComprada INTEGER,
        quantidadeAtual INTEGER,
        precoPacotePago REAL,
        codigoBarrasEan TEXT,
        fornecedorOndeComprou TEXT,
        linkCompra TEXT,
        observacoes TEXT
      )
    ''');

    // 6. Canais de Venda
    await db.execute('''
      CREATE TABLE IF NOT EXISTS canais_venda (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        comissaoPercentual REAL,
        taxaFixaPorVenda REAL,
        taxaAntecipacaoPercentual REAL
      )
    ''');

    // 7. Formas de Pagamento
    await db.execute('''
      CREATE TABLE IF NOT EXISTS formas_pagamento (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        taxaPercentual REAL,
        diasParaCair INTEGER
      )
    ''');

    // 8. Clientes
    await db.execute('''
      CREATE TABLE IF NOT EXISTS clientes (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        telefoneWhatsapp TEXT,
        email TEXT,
        cpfCnpj TEXT,
        cep TEXT,
        endereco TEXT,
        numero TEXT,
        complemento TEXT,
        bairro TEXT,
        cidade TEXT,
        estado TEXT,
        observacoes TEXT
      )
    ''');

    // 9. Produtos
    await db.execute('''
      CREATE TABLE IF NOT EXISTS produtos (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        impressoraPadraoId TEXT,
        tempoImpressaoMinutos INTEGER,
        tempoMaoDeObraMinutos INTEGER,
        pesoPurgaSuporteGramas REAL,
        quantidadeTrocasFilamento INTEGER DEFAULT 0,
        estoqueProntoUnidades INTEGER DEFAULT 0,
        precoVendaSugerido REAL,
        codigoBarrasProduto TEXT,
        linkModeloOriginal TEXT,
        licencaComercial TEXT,
        arquivoFatiadoNome TEXT,
        arquivoFatiadoPathLocal TEXT,
        thumbnailPath TEXT
      )
    ''');

    // 10. Produto Filamentos (N:N)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS produto_filamentos (
        id TEXT PRIMARY KEY,
        produtoId TEXT NOT NULL,
        filamentoId TEXT NOT NULL,
        pesoUtilizadoGramas REAL,
        slotAms INTEGER DEFAULT 1
      )
    ''');

    // 11. Produto Insumos (N:N)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS produto_insumos (
        id TEXT PRIMARY KEY,
        produtoId TEXT NOT NULL,
        insumoId TEXT NOT NULL,
        quantidadeUtilizada INTEGER
      )
    ''');

    // 12. Vendas e Orçamentos
    await db.execute('''
      CREATE TABLE IF NOT EXISTS vendas (
        id TEXT PRIMARY KEY,
        codigoOrcamento TEXT,
        clienteId TEXT,
        canalVendaId TEXT,
        formaPagamentoId TEXT,
        dataCriacao TEXT,
        dataValidade TEXT,
        valorTotal REAL,
        valorFreteCobrado REAL DEFAULT 0,
        custoFretePago REAL DEFAULT 0,
        descontoAplicado REAL DEFAULT 0,
        valorJaPago REAL DEFAULT 0,
        statusOrcamento TEXT DEFAULT 'PENDENTE',
        statusPagamento TEXT DEFAULT 'PENDENTE',
        statusProducao TEXT DEFAULT 'ORCAMENTO',
        observacoes TEXT
      )
    ''');

    // 13. Venda Itens (N:N)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS venda_itens (
        id TEXT PRIMARY KEY,
        vendaId TEXT NOT NULL,
        produtoId TEXT NOT NULL,
        quantidade INTEGER,
        precoUnitarioPraticado REAL,
        custoUnitarioNaEpoca REAL
      )
    ''');

    // 14. Histórico Produção
    await db.execute('''
      CREATE TABLE IF NOT EXISTS historico_producao (
        id TEXT PRIMARY KEY,
        vendaId TEXT,
        produtoId TEXT NOT NULL,
        impressoraId TEXT NOT NULL,
        dataProducao TEXT,
        quantidadeProduzida INTEGER,
        status TEXT,
        custoTotalProducao REAL,
        observacoes TEXT
      )
    ''');

    // 15. Movimentações de Caixa
    await db.execute('''
      CREATE TABLE IF NOT EXISTS movimentacoes_caixa (
        id TEXT PRIMARY KEY,
        tipo TEXT NOT NULL,
        categoria TEXT NOT NULL,
        referenciaId TEXT,
        descricao TEXT,
        valor REAL,
        dataMovimentacao TEXT,
        status TEXT
      )
    ''');

    // 16. Avarias e Perdas (Requisito Especial)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS avarias (
        id TEXT PRIMARY KEY,
        tipoItem TEXT NOT NULL,
        itemId TEXT NOT NULL,
        itemNome TEXT NOT NULL,
        quantidadePerdida REAL,
        unidade TEXT,
        custoEstimadoPerda REAL,
        motivo TEXT NOT NULL,
        dataAvaria TEXT,
        observacoes TEXT
      )
    ''');

    // Inserir dados padrão no SQLite
    await _seedDefaults(db);
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await _onCreate(db, newVersion);
    }
  }

  static Future<void> _seedDefaults(Database db) async {
    for (final table in _webStore.keys) {
      final items = _webStore[table]!;
      for (final item in items) {
        await db.insert(table, item, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }
  }

  // ==========================================
  // PERSISTÊNCIA WEB (SHARED PREFERENCES / LOCALSTORAGE)
  // ==========================================
  static Future<void> init() async {
    if (!kIsWeb) {
      await database;
      return;
    }
    await _ensureWebInit();
  }

  static Future<void> _ensureWebInit() async {
    if (!kIsWeb || _webInitialized) return;
    _webInitialized = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_webStorageKey);
      if (savedJson != null && savedJson.isNotEmpty) {
        final decoded = jsonDecode(savedJson) as Map<String, dynamic>;
        for (final key in decoded.keys) {
          final list = (decoded[key] as List?)
                  ?.map((e) => Map<String, dynamic>.from(e as Map))
                  .toList() ??
              [];
          _webStore[key] = list;
        }
      } else {
        await _persistWebStore();
      }
    } catch (e) {
      debugPrint('Aviso ao carregar persistência Web: $e');
    }
  }

  static Future<void> _persistWebStore() async {
    if (!kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_webStorageKey, jsonEncode(_webStore));
    } catch (e) {
      debugPrint('Aviso ao salvar persistência Web: $e');
    }
  }

  // ==========================================
  // OPERAÇÕES GENÉRICAS CRUD
  // ==========================================
  static Future<List<Map<String, dynamic>>> getAll(String table) async {
    if (kIsWeb) {
      await _ensureWebInit();
      final list = _webStore[table] ?? [];
      return list.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    final db = await database;
    return await db.query(table);
  }

  static Future<Map<String, dynamic>?> getById(String table, String id) async {
    if (kIsWeb) {
      await _ensureWebInit();
      final list = _webStore[table] ?? [];
      final match = list.where((e) => e['id'] == id);
      if (match.isEmpty) return null;
      return Map<String, dynamic>.from(match.first);
    }
    final db = await database;
    final results = await db.query(table, where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  static Future<void> insert(String table, Map<String, dynamic> data) async {
    final values = Map<String, dynamic>.from(data);
    if (!values.containsKey('id') || values['id'] == null || values['id'].toString().isEmpty) {
      values['id'] = _uuid.v4();
    }

    if (kIsWeb) {
      await _ensureWebInit();
      final list = _webStore.putIfAbsent(table, () => []);
      final existingIdx = list.indexWhere((e) => e['id'] == values['id']);
      if (existingIdx >= 0) {
        list[existingIdx] = values;
      } else {
        list.add(values);
      }
      await _persistWebStore();
      return;
    }

    final db = await database;
    await db.insert(table, values, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> update(String table, Map<String, dynamic> data, String id) async {
    final values = Map<String, dynamic>.from(data);
    values['id'] = id;

    if (kIsWeb) {
      await _ensureWebInit();
      final list = _webStore[table] ?? [];
      final index = list.indexWhere((e) => e['id'] == id);
      if (index >= 0) {
        list[index] = values;
      } else {
        list.add(values);
      }
      await _persistWebStore();
      return;
    }

    final db = await database;
    await db.update(table, values, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> delete(String table, String id) async {
    if (kIsWeb) {
      await _ensureWebInit();
      final list = _webStore[table] ?? [];
      list.removeWhere((e) => e['id'] == id);
      await _persistWebStore();
      return;
    }

    final db = await database;
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // AUTENTICAÇÃO E USUÁRIOS
  // ==========================================
  static Future<void> ensureDemoUser() async {
    if (kIsWeb) {
      final users = _webStore['usuarios']!;
      if (!users.any((u) => u['email'] == 'admin@teste.com')) {
        users.add({
          'id': 1,
          'email': 'admin@teste.com',
          'senha': '123456',
          'nome': 'Administrador',
          'provider': 'local',
        });
      }
      return;
    }

    final db = await database;
    final result = await db.query(
      'usuarios',
      where: 'email = ?',
      whereArgs: ['admin@teste.com'],
    );

    if (result.isEmpty) {
      await db.insert('usuarios', {
        'email': 'admin@teste.com',
        'senha': '123456',
        'nome': 'Administrador',
        'provider': 'local',
      });
    }
  }

  static Future<Map<String, dynamic>?> login(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (kIsWeb) {
      await _ensureWebInit();
      final match = _webStore['usuarios']!.where(
        (u) => u['email'] == normalizedEmail && u['senha'] == password,
      );
      if (match.isEmpty) return null;
      return Map<String, dynamic>.from(match.first);
    }

    final db = await database;
    final result = await db.query(
      'usuarios',
      where: 'email = ? AND senha = ?',
      whereArgs: [normalizedEmail, password],
    );

    return result.isNotEmpty ? result.first : null;
  }

  static Future<void> upsertSocialUser({
    required String email,
    required String name,
    required String provider,
    required String firebaseUid,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (kIsWeb) {
      await _ensureWebInit();
      final users = _webStore['usuarios']!;
      final index = users.indexWhere((u) => u['email'] == normalizedEmail);
      final userRecord = {
        'id': index >= 0 ? users[index]['id'] : users.length + 1,
        'email': normalizedEmail,
        'senha': firebaseUid,
        'nome': name,
        'provider': provider,
      };

      if (index >= 0) {
        users[index] = userRecord;
      } else {
        users.add(userRecord);
      }
      await _persistWebStore();
      return;
    }

    final db = await database;
    final existing = await db.query(
      'usuarios',
      where: 'email = ?',
      whereArgs: [normalizedEmail],
    );

    final values = {
      'email': normalizedEmail,
      'senha': firebaseUid,
      'nome': name,
      'provider': provider,
    };

    if (existing.isEmpty) {
      await db.insert('usuarios', values);
    } else {
      await db.update('usuarios', values, where: 'email = ?', whereArgs: [normalizedEmail]);
    }
  }

  static Future<int> registerUser({
    required String email,
    required String password,
    required String name,
    String provider = 'local',
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (kIsWeb) {
      await _ensureWebInit();
      final users = _webStore['usuarios']!;
      if (users.any((u) => u['email'] == normalizedEmail)) {
        throw Exception('Usuário já cadastrado.');
      }
      final newId = users.length + 1;
      users.add({
        'id': newId,
        'email': normalizedEmail,
        'senha': password,
        'nome': name,
        'provider': provider,
      });
      await _persistWebStore();
      return newId;
    }

    final db = await database;
    final exists = await db.query(
      'usuarios',
      where: 'email = ?',
      whereArgs: [normalizedEmail],
    );

    if (exists.isNotEmpty) {
      throw Exception('Usuário já cadastrado.');
    }

    return db.insert('usuarios', {
      'email': normalizedEmail,
      'senha': password,
      'nome': name,
      'provider': provider,
    });
  }

  // ==========================================
  // GESTÃO DE ESTOQUE E BAIXA DE FILAMENTO / INSUMO
  // ==========================================
  static Future<void> darBaixaEstoqueFilamento({
    required String filamentoId,
    required double pesoGramas,
  }) async {
    final fil = await getById('filamentos', filamentoId);
    if (fil == null) return;

    final atual = (fil['pesoAtualGramas'] as num).toDouble();
    final novoPeso = (atual - pesoGramas).clamp(0.0, 999999.0);

    final updated = Map<String, dynamic>.from(fil);
    updated['pesoAtualGramas'] = novoPeso;
    await update('filamentos', updated, filamentoId);
  }

  static Future<void> darBaixaEstoqueInsumo({
    required String insumoId,
    required int quantidade,
  }) async {
    final ins = await getById('insumos', insumoId);
    if (ins == null) return;

    final atual = (ins['quantidadeAtual'] as num).toInt();
    final novaQtd = (atual - quantidade).clamp(0, 999999);

    final updated = Map<String, dynamic>.from(ins);
    updated['quantidadeAtual'] = novaQtd;
    await update('insumos', updated, insumoId);
  }

  // ==========================================
  // REGISTRO DE AVARIAS E PERDAS
  // ==========================================
  static Future<void> registrarAvaria({
    required String tipoItem, // 'FILAMENTO', 'INSUMO', 'PRODUTO'
    required String itemId,
    required String itemNome,
    required double quantidadePerdida,
    required String unidade,
    required double custoEstimadoPerda,
    required String motivo,
    String? observacoes,
  }) async {
    final avariaId = _uuid.v4();
    final agora = DateTime.now().toIso8601String();

    // 1. Salvar na tabela de avarias
    await insert('avarias', {
      'id': avariaId,
      'tipoItem': tipoItem,
      'itemId': itemId,
      'itemNome': itemNome,
      'quantidadePerdida': quantidadePerdida,
      'unidade': unidade,
      'custoEstimadoPerda': custoEstimadoPerda,
      'motivo': motivo,
      'dataAvaria': agora,
      'observacoes': observacoes ?? '',
    });

    // 2. Dar baixa automática no estoque correspondente
    if (tipoItem == 'FILAMENTO') {
      await darBaixaEstoqueFilamento(
        filamentoId: itemId,
        pesoGramas: quantidadePerdida,
      );
    } else if (tipoItem == 'INSUMO') {
      await darBaixaEstoqueInsumo(
        insumoId: itemId,
        quantidade: quantidadePerdida.toInt(),
      );
    } else if (tipoItem == 'PRODUTO') {
      final prod = await getById('produtos', itemId);
      if (prod != null) {
        final atual = (prod['estoqueProntoUnidades'] as num?)?.toInt() ?? 0;
        final updated = Map<String, dynamic>.from(prod);
        updated['estoqueProntoUnidades'] = (atual - quantidadePerdida.toInt()).clamp(0, 999999);
        await update('produtos', updated, itemId);
      }
    }

    // 3. Registrar saída/perda no Caixa
    await insert('movimentacoes_caixa', {
      'id': _uuid.v4(),
      'tipo': 'SAIDA_DESPESA',
      'categoria': 'AVARIA',
      'referenciaId': avariaId,
      'descricao': 'Perda/Avaria: $itemNome ($motivo)',
      'valor': custoEstimadoPerda,
      'dataMovimentacao': agora,
      'status': 'PAGO',
    });
  }

  // ==========================================
  // EXPORTAÇÃO E BACKUP DE DADOS (JSON)
  // ==========================================
  static Future<String> exportarBancoJson() async {
    final Map<String, dynamic> exportMap = {};

    for (final table in _webStore.keys) {
      exportMap[table] = await getAll(table);
    }

    return const JsonEncoder.withIndent('  ').convert(exportMap);
  }

  static Future<void> importarBancoJson(String jsonString) async {
    final Map<String, dynamic> data = jsonDecode(jsonString);

    for (final table in data.keys) {
      final list = (data[table] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (final item in list) {
        if (item.containsKey('id') && item['id'] != null) {
          await insert(table, item);
        }
      }
    }
  }
}
