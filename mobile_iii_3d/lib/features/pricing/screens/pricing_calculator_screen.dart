import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../database/db_helper.dart';
import '../../../services/pricing_calculator_service.dart';
import '../../../services/slicer_parser_service.dart';

class PricingCalculatorScreen extends StatefulWidget {
  const PricingCalculatorScreen({super.key});

  @override
  State<PricingCalculatorScreen> createState() => _PricingCalculatorScreenState();
}

class _PricingCalculatorScreenState extends State<PricingCalculatorScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  // Dados carregados do banco
  List<Map<String, dynamic>> _impressoras = [];
  List<Map<String, dynamic>> _filamentosEstoque = [];
  List<Map<String, dynamic>> _insumosEstoque = [];
  List<Map<String, dynamic>> _canaisVenda = [];
  List<Map<String, dynamic>> _formasPagamento = [];
  Map<String, dynamic>? _configGeral;

  // Estado do formulário
  final _nomeItemController = TextEditingController(text: 'Novo Projeto 3D');
  String? _impressoraSelecionadaId;
  String? _canalVendaSelecionadoId;
  String? _formaPagamentoSelecionadaId;

  final _tempoImpressaoController = TextEditingController(text: '120');
  final _tempoMaoDeObraController = TextEditingController(text: '15');
  final _trocasFilamentoController = TextEditingController(text: '0');
  final _pesoPurgaController = TextEditingController(text: '0.0');
  final _segundosPorTrocaController = TextEditingController(text: '75');

  // Filamentos adicionados (Slots do AMS ou monocolor)
  final List<FilamentCostItem> _filamentosSlots = [];

  // Insumos adicionados
  final List<InsumoCostItem> _insumosAdicionados = [];

  // Margens
  double _margemLucro = 100.0;
  double _taxaFalha = 10.0;
  bool _isLoading = true;
  String? _arquivoImportadoNome;

  @override
  void initState() {
    super.initState();
    _carregarDadosIniciais();
  }

  @override
  void dispose() {
    _nomeItemController.dispose();
    _tempoImpressaoController.dispose();
    _tempoMaoDeObraController.dispose();
    _trocasFilamentoController.dispose();
    _pesoPurgaController.dispose();
    _segundosPorTrocaController.dispose();
    super.dispose();
  }

  Future<void> _carregarDadosIniciais() async {
    setState(() => _isLoading = true);
    final configs = await DbHelper.getAll('configuracoes_gerais');
    final imps = await DbHelper.getAll('impressoras');
    final fils = await DbHelper.getAll('filamentos');
    final ins = await DbHelper.getAll('insumos');
    final canais = await DbHelper.getAll('canais_venda');
    final formas = await DbHelper.getAll('formas_pagamento');

    _configGeral = configs.isNotEmpty ? configs.first : null;
    _impressoras = imps;
    _filamentosEstoque = fils;
    _insumosEstoque = ins;
    _canaisVenda = canais;
    _formasPagamento = formas;

    if (_configGeral != null) {
      _margemLucro = (_configGeral!['margemLucroPadraoPercentual'] as num?)?.toDouble() ?? 100.0;
      _taxaFalha = (_configGeral!['taxaFalhaPadraoPercentual'] as num?)?.toDouble() ?? 10.0;
    }

    if (_impressoras.isNotEmpty && _impressoraSelecionadaId == null) {
      _impressoraSelecionadaId = _impressoras.first['id'];
    }
    if (_canaisVenda.isNotEmpty && _canalVendaSelecionadoId == null) {
      _canalVendaSelecionadoId = _canaisVenda.first['id'];
    }
    if (_formasPagamento.isNotEmpty && _formaPagamentoSelecionadaId == null) {
      _formaPagamentoSelecionadaId = _formasPagamento.first['id'];
    }

    if (_filamentosEstoque.isNotEmpty && _filamentosSlots.isEmpty) {
      final f = _filamentosEstoque.first;
      final pesoInicial = (f['pesoInicialGramas'] as num?)?.toDouble() ?? 1000.0;
      final precoPago = (f['precoPago'] as num?)?.toDouble() ?? 120.0;
      final precoKg = pesoInicial > 0 ? (precoPago / pesoInicial) * 1000.0 : precoPago;

      _filamentosSlots.add(FilamentCostItem(
        filamentoId: f['id'],
        nomeCor: '${f['marca']} - ${f['corNome'] ?? 'Padrão'}',
        material: f['material'] ?? 'PLA',
        precoPorQuilo: precoKg,
        pesoGramas: 50.0,
        slotAms: 1,
      ));
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // ==========================================
  // MODAL: SELECIONAR E ADICIONAR FILAMENTO / SLOT AMS
  // ==========================================
  Future<void> _abrirModalAdicionarFilamento({int? editIndex}) async {
    if (_filamentosEstoque.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhum carretel cadastrado no Estoque. Cadastre um filamento primeiro!'),
          backgroundColor: Color(0xFFD97706),
        ),
      );
      return;
    }

    final existing = editIndex != null ? _filamentosSlots[editIndex] : null;
    String selectedId = existing?.filamentoId ?? _filamentosEstoque.first['id'];
    if (!_filamentosEstoque.any((f) => f['id'] == selectedId)) {
      selectedId = _filamentosEstoque.first['id'];
    }

    final pesoCtrl = TextEditingController(
      text: existing != null ? existing.pesoGramas.toStringAsFixed(1) : '35.0',
    );
    final slotCtrl = TextEditingController(
      text: (existing?.slotAms ?? (_filamentosSlots.length + 1)).toString(),
    );

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            title: Text(existing != null ? 'Editar Filamento / Slot' : 'Adicionar Filamento / Slot AMS'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Escolha o Carretel do Estoque',
                      border: OutlineInputBorder(),
                    ),
                    items: _filamentosEstoque.map((f) {
                      final pesoAtual = (f['pesoAtualGramas'] as num?)?.toDouble() ?? 0.0;
                      return DropdownMenuItem<String>(
                        value: f['id'],
                        child: Text(
                          '${f['marca']} • ${f['corNome']} (${f['material']}) - ${pesoAtual.toStringAsFixed(0)}g',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDlgState(() => selectedId = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: pesoCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Peso Utilizado (g)',
                            border: OutlineInputBorder(),
                            suffixText: 'g',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: slotCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Slot AMS',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () {
                  final fil = _filamentosEstoque.firstWhere((f) => f['id'] == selectedId);
                  final pesoInicial = (fil['pesoInicialGramas'] as num?)?.toDouble() ?? 1000.0;
                  final precoPago = (fil['precoPago'] as num?)?.toDouble() ?? 120.0;
                  final precoKg = pesoInicial > 0 ? (precoPago / pesoInicial) * 1000.0 : precoPago;

                  final novoItem = FilamentCostItem(
                    filamentoId: fil['id'],
                    nomeCor: '${fil['marca']} - ${fil['corNome']}',
                    material: fil['material'] ?? 'PLA',
                    precoPorQuilo: precoKg,
                    pesoGramas: double.tryParse(pesoCtrl.text.replaceAll(',', '.')) ?? 30.0,
                    slotAms: int.tryParse(slotCtrl.text) ?? 1,
                  );

                  setState(() {
                    if (editIndex != null) {
                      _filamentosSlots[editIndex] = novoItem;
                    } else {
                      _filamentosSlots.add(novoItem);
                    }
                  });
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                ),
                child: Text(existing != null ? 'Atualizar' : 'Adicionar'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==========================================
  // MODAL: SELECIONAR E ADICIONAR INSUMO / EMBALAGEM
  // ==========================================
  Future<void> _abrirModalAdicionarInsumo() async {
    if (_insumosEstoque.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhum insumo cadastrado no Estoque. Cadastre um insumo primeiro!'),
          backgroundColor: Color(0xFFD97706),
        ),
      );
      return;
    }

    String selectedId = _insumosEstoque.first['id'];
    final qtdCtrl = TextEditingController(text: '1');

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final ins = _insumosEstoque.firstWhere((i) => i['id'] == selectedId);
          final precoPacote = (ins['precoPacotePago'] as num?)?.toDouble() ?? 0.0;
          final qtdComprada = (ins['quantidadeComprada'] as num?)?.toInt() ?? 1;
          final custoUnit = qtdComprada > 0 ? (precoPacote / qtdComprada) : 0.0;

          return AlertDialog(
            title: const Text('Selecionar Insumo / Embalagem'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Escolha o Insumo do Estoque',
                      border: OutlineInputBorder(),
                    ),
                    items: _insumosEstoque.map((i) {
                      final pPct = (i['precoPacotePago'] as num?)?.toDouble() ?? 0.0;
                      final qComp = (i['quantidadeComprada'] as num?)?.toInt() ?? 1;
                      final cUnit = qComp > 0 ? (pPct / qComp) : 0.0;
                      return DropdownMenuItem<String>(
                        value: i['id'],
                        child: Text(
                          '${i['nome']} (${_currencyFormat.format(cUnit)}/un • Saldo: ${i['quantidadeAtual']})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDlgState(() => selectedId = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: qtdCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantidade Utilizada (un)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setDlgState(() {}),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Custo unitário: ${_currencyFormat.format(custoUnit)}',
                    style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () {
                  final qtd = int.tryParse(qtdCtrl.text) ?? 1;
                  if (qtd <= 0) return;

                  setState(() {
                    final existingIdx = _insumosAdicionados.indexWhere((e) => e.insumoId == selectedId);
                    if (existingIdx >= 0) {
                      final old = _insumosAdicionados[existingIdx];
                      _insumosAdicionados[existingIdx] = InsumoCostItem(
                        insumoId: old.insumoId,
                        nome: old.nome,
                        custoUnitario: custoUnit,
                        quantidade: old.quantidade + qtd,
                      );
                    } else {
                      _insumosAdicionados.add(InsumoCostItem(
                        insumoId: ins['id'],
                        nome: ins['nome'] ?? 'Insumo',
                        custoUnitario: custoUnit,
                        quantidade: qtd,
                      ));
                    }
                  });
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Adicionar Insumo'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==========================================
  // CARREGAR ARQUIVO .3MF / GCODE
  // ==========================================
  Future<void> _selecionarArquivo3D() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['3mf', 'gcode'],
    );

    if (files.isEmpty) return;

    final file = files.first;
    final bytes = await file.xFile.readAsBytes();

    final name = file.name;
    SlicerParseResult parseResult;

    if (name.toLowerCase().endsWith('.3mf')) {
      parseResult = SlicerParserService.parse3mfBytes(bytes, name);
    } else {
      final content = String.fromCharCodes(bytes);
      parseResult = SlicerParserService.parseGcodeString(content, name);
    }

    setState(() {
      _arquivoImportadoNome = name;
      _nomeItemController.text = name.replaceAll('.3mf', '').replaceAll('.gcode', '');
      if (parseResult.totalTimeMinutes > 0) {
        _tempoImpressaoController.text = parseResult.totalTimeMinutes.toString();
      }
      _trocasFilamentoController.text = parseResult.filamentChanges.toString();
      _pesoPurgaController.text = parseResult.purgeWeightGrams.toStringAsFixed(1);

      if (parseResult.filaments.isNotEmpty) {
        _filamentosSlots.clear();
        for (final pf in parseResult.filaments) {
          final matchedFil = _filamentosEstoque.firstWhere(
            (f) =>
                f['material'].toString().toLowerCase() == pf.material.toLowerCase() ||
                f['corNome'].toString().toLowerCase().contains(pf.material.toLowerCase()),
            orElse: () => _filamentosEstoque.isNotEmpty
                ? _filamentosEstoque.first
                : {
                    'id': null,
                    'precoPago': 120.0,
                    'pesoInicialGramas': 1000.0,
                    'corNome': 'Slot ${pf.slotIndex}',
                    'marca': 'Genérico',
                    'material': pf.material,
                  },
          );

          final pesoInicial = (matchedFil['pesoInicialGramas'] as num?)?.toDouble() ?? 1000.0;
          final precoPago = (matchedFil['precoPago'] as num?)?.toDouble() ?? 120.0;
          final precoKg = pesoInicial > 0 ? (precoPago / pesoInicial) * 1000.0 : precoPago;

          _filamentosSlots.add(FilamentCostItem(
            filamentoId: matchedFil['id'],
            nomeCor: '${matchedFil['marca'] ?? ''} - ${matchedFil['corNome']} (${pf.material})',
            material: pf.material,
            precoPorQuilo: precoKg,
            pesoGramas: pf.weightGrams,
            slotAms: pf.slotIndex,
          ));
        }
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Arquivo "$name" importado! '
            '${parseResult.filaments.length} cor(es), ${parseResult.filamentChanges} trocas.',
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  // ==========================================
  // CÁLCULO ATUALIZADO
  // ==========================================
  PricingCalculationResult _calcularResultado() {
    final imp = _impressoras.firstWhere(
      (i) => i['id'] == _impressoraSelecionadaId,
      orElse: () => {
        'potenciaWatts': 150,
        'valorAquisicao': 2500.0,
        'vidaUtilHoras': 3000,
        'custoManutencaoHora': 0.80,
      },
    );

    final canal = _canaisVenda.firstWhere(
      (c) => c['id'] == _canalVendaSelecionadoId,
      orElse: () => {
        'comissaoPercentual': 0.0,
        'taxaFixaPorVenda': 0.0,
        'taxaAntecipacaoPercentual': 0.0,
      },
    );

    final forma = _formasPagamento.firstWhere(
      (f) => f['id'] == _formaPagamentoSelecionadaId,
      orElse: () => {'taxaPercentual': 0.0},
    );

    final comissao = (canal['comissaoPercentual'] as num?)?.toDouble() ?? 0.0;
    final antecipacao = (canal['taxaAntecipacaoPercentual'] as num?)?.toDouble() ?? 0.0;
    final taxaFixa = (canal['taxaFixaPorVenda'] as num?)?.toDouble() ?? 0.0;
    final taxaPag = (forma['taxaPercentual'] as num?)?.toDouble() ?? 0.0;

    return PricingCalculatorService.calculate(
      filamentos: _filamentosSlots,
      pesoPurgaSuporteGramas: double.tryParse(_pesoPurgaController.text.replaceAll(',', '.')) ?? 0.0,
      quantidadeTrocasFilamento: int.tryParse(_trocasFilamentoController.text) ?? 0,
      segundosPorTroca: int.tryParse(_segundosPorTrocaController.text) ?? 75,
      insumos: _insumosAdicionados,
      tempoImpressaoFatiadorMinutos: int.tryParse(_tempoImpressaoController.text) ?? 0,
      potenciaWatts: (imp['potenciaWatts'] as num?)?.toInt() ?? 150,
      valorKwh: (_configGeral?['valorKwh'] as num?)?.toDouble() ?? 0.95,
      valorAquisicaoImpressora: (imp['valorAquisicao'] as num?)?.toDouble() ?? 2500.0,
      vidaUtilHoras: (imp['vidaUtilHoras'] as num?)?.toInt() ?? 3000,
      custoManutencaoHora: (imp['custoManutencaoHora'] as num?)?.toDouble() ?? 0.80,
      tempoMaoDeObraMinutos: int.tryParse(_tempoMaoDeObraController.text) ?? 15,
      valorHoraMaoDeObra: (_configGeral?['valorHoraMaoDeObra'] as num?)?.toDouble() ?? 25.0,
      taxaFalhaPercentual: _taxaFalha,
      margemLucroPercentual: _margemLucro,
      comissaoMarketplacePercentual: comissao + antecipacao,
      taxaFixaMarketplace: taxaFixa,
      taxaPagamentoPercentual: taxaPag,
      taxaImpostoPercentual: (_configGeral?['taxaImpostoPercentual'] as num?)?.toDouble() ?? 6.0,
    );
  }

  // ==========================================
  // SALVAR COMO PRODUTO NO CATÁLOGO
  // ==========================================
  Future<void> _salvarNoCatalogoProdutos(PricingCalculationResult calc) async {
    final prodId = 'prod_${DateTime.now().millisecondsSinceEpoch}';
    final eanCtrl = TextEditingController(text: '7893D${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    final estoqueProntoCtrl = TextEditingController(text: '0');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Salvar no Catálogo de Produtos'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Produto: ${_nomeItemController.text}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Preço Sugerido: ${_currencyFormat.format(calc.precoMarketplaceSugerido)}'),
            const SizedBox(height: 12),
            TextFormField(
              controller: eanCtrl,
              decoration: const InputDecoration(
                labelText: 'Código de Barras do Produto',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: estoqueProntoCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Estoque Pronto em Prateleira (un)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              await DbHelper.insert('produtos', {
                'id': prodId,
                'nome': _nomeItemController.text.trim(),
                'impressoraPadraoId': _impressoraSelecionadaId,
                'tempoImpressaoMinutos': calc.tempoTotalEfetivoMinutos,
                'tempoMaoDeObraMinutos': int.tryParse(_tempoMaoDeObraController.text) ?? 15,
                'pesoPurgaSuporteGramas': double.tryParse(_pesoPurgaController.text) ?? 0.0,
                'quantidadeTrocasFilamento': int.tryParse(_trocasFilamentoController.text) ?? 0,
                'estoqueProntoUnidades': int.tryParse(estoqueProntoCtrl.text) ?? 0,
                'precoVendaSugerido': calc.precoMarketplaceSugerido,
                'codigoBarrasProduto': eanCtrl.text.trim(),
                'arquivoFatiadoNome': _arquivoImportadoNome ?? '',
              });

              for (final f in _filamentosSlots) {
                if (f.filamentoId != null) {
                  await DbHelper.insert('produto_filamentos', {
                    'produtoId': prodId,
                    'filamentoId': f.filamentoId,
                    'pesoUtilizadoGramas': f.pesoGramas,
                    'slotAms': f.slotAms,
                  });
                }
              }

              for (final ins in _insumosAdicionados) {
                if (ins.insumoId != null) {
                  await DbHelper.insert('produto_insumos', {
                    'produtoId': prodId,
                    'insumoId': ins.insumoId,
                    'quantidadeUtilizada': ins.quantidade,
                  });
                }
              }

              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Produto salvo no Catálogo com receita de filamentos e insumos!'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
            ),
            child: const Text('Salvar Produto'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SALVAR COMO ORÇAMENTO
  // ==========================================
  Future<void> _salvarComoOrcamento(PricingCalculationResult calc) async {
    final clientes = await DbHelper.getAll('clientes');
    String? clienteIdSelecionado = clientes.isNotEmpty ? clientes.first['id'] : null;
    final descontoCtrl = TextEditingController(text: '0.00');
    final sinalCtrl = TextEditingController(text: '0.00');

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            final desconto = double.tryParse(descontoCtrl.text.replaceAll(',', '.')) ?? 0.0;
            final valorFinal = (calc.precoMarketplaceSugerido - desconto).clamp(0.0, 999999.0);

            return AlertDialog(
              title: const Text('Salvar como Orçamento'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Selecione o cliente:'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: clienteIdSelecionado,
                      isExpanded: true,
                      items: clientes.map((c) {
                        return DropdownMenuItem<String>(
                          value: c['id'],
                          child: Text(c['nome'] ?? 'Sem nome'),
                        );
                      }).toList(),
                      onChanged: (val) => setDlgState(() => clienteIdSelecionado = val),
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: descontoCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Desconto (R\$)',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => setDlgState(() {}),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: sinalCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Sinal Pago (R\$)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Valor Final do Orçamento: ${_currencyFormat.format(valorFinal)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5), fontSize: 16),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final numOrc = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
                    final sinal = double.tryParse(sinalCtrl.text.replaceAll(',', '.')) ?? 0.0;
                    final statusPag = sinal >= valorFinal && valorFinal > 0
                        ? 'PAGO'
                        : sinal > 0
                            ? 'PARCIAL'
                            : 'PENDENTE';

                    await DbHelper.insert('vendas', {
                      'codigoOrcamento': 'ORC-$numOrc',
                      'clienteId': clienteIdSelecionado,
                      'canalVendaId': _canalVendaSelecionadoId,
                      'formaPagamentoId': _formaPagamentoSelecionadaId,
                      'dataCriacao': DateTime.now().toIso8601String(),
                      'dataValidade': DateTime.now().add(const Duration(days: 15)).toIso8601String(),
                      'valorTotal': valorFinal,
                      'descontoAplicado': desconto,
                      'valorJaPago': sinal,
                      'statusOrcamento': 'PENDENTE',
                      'statusProducao': 'ORCAMENTO',
                      'statusPagamento': statusPag,
                      'observacoes': 'Item: ${_nomeItemController.text} | '
                          'Tempo: ${calc.tempoTotalEfetivoMinutos} min | '
                          'Filamentos: ${_filamentosSlots.map((f) => "${f.nomeCor} ${f.pesoGramas}g").join(", ")}'
                          '${_insumosAdicionados.isNotEmpty ? " | Insumos: ${_insumosAdicionados.map((i) => "${i.quantidade}x ${i.nome}").join(", ")}" : ""}',
                    });

                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Orçamento salvo com status PENDENTE!'),
                          backgroundColor: Color(0xFF10B981),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Confirmar Orçamento'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final calc = _calcularResultado();
    final isWide = MediaQuery.of(context).size.width >= 850;

    final formPane = SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            onPressed: _selecionarArquivo3D,
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('Carregar Arquivo .3MF (Bambu/OrcaSlicer/Prusa)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEEF2FF),
              foregroundColor: const Color(0xFF4F46E5),
              elevation: 0,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _nomeItemController,
            decoration: const InputDecoration(
              labelText: 'Nome do Projeto / Peça',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),

          // Impressora e Tempo
          Row(
            children: [
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  value: _impressoraSelecionadaId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Impressora',
                    border: OutlineInputBorder(),
                  ),
                  items: _impressoras.map((i) {
                    return DropdownMenuItem<String>(
                      value: i['id'],
                      child: Text(i['nome'] ?? '', overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _impressoraSelecionadaId = val),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _tempoImpressaoController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Tempo Fatiador (min)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Canal de Venda e Forma de Pagamento
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _canalVendaSelecionadoId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Canal de Venda',
                    border: OutlineInputBorder(),
                  ),
                  items: _canaisVenda.map((c) {
                    return DropdownMenuItem<String>(
                      value: c['id'],
                      child: Text('${c['nome']} (${c['comissaoPercentual']}%)', overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _canalVendaSelecionadoId = val),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _formaPagamentoSelecionadaId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Forma de Pagamento',
                    border: OutlineInputBorder(),
                  ),
                  items: _formasPagamento.map((f) {
                    return DropdownMenuItem<String>(
                      value: f['id'],
                      child: Text('${f['nome']} (${f['taxaPercentual']}%)', overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _formaPagamentoSelecionadaId = val),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ==============================
          // SEÇÃO: FILAMENTOS & AMS SLOTS
          // ==============================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Filamentos & Slots AMS (Multicor)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Adicionar Cor/Slot'),
                onPressed: () => _abrirModalAdicionarFilamento(),
              ),
            ],
          ),
          const SizedBox(height: 6),

          if (_filamentosSlots.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Nenhum filamento adicionado. Clique em "+ Adicionar Cor/Slot".', style: TextStyle(color: Colors.grey)),
            ),

          ..._filamentosSlots.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => _abrirModalAdicionarFilamento(editIndex: index),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: const Color(0xFF4F46E5),
                        child: Text(
                          '${item.slotAms}',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.nomeCor,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${item.material} • ${_currencyFormat.format(item.precoPorQuilo)}/kg',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${item.pesoGramas.toStringAsFixed(1)}g',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          _currencyFormat.format(item.custoTotal),
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        onPressed: () {
                          setState(() => _filamentosSlots.removeAt(index));
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 12),

          // Campos de Trocas e Purga (AMS)
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _trocasFilamentoController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Trocas de Filamento',
                    hintText: 'Ex: 124',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _segundosPorTrocaController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Seg/Troca AMS',
                    hintText: '75s',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _pesoPurgaController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Purga / Flush (g)',
                    hintText: 'Ex: 35.5',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ==============================
          // SEÇÃO: INSUMOS & ACESSÓRIOS
          // ==============================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Insumos e Embalagens',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Adicionar Insumo'),
                onPressed: _abrirModalAdicionarInsumo,
              ),
            ],
          ),
          if (_insumosAdicionados.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text('Nenhum insumo adicionado (opcional).', style: TextStyle(color: Colors.grey, fontSize: 13)),
            ),
          ..._insumosAdicionados.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.extension_rounded, size: 20, color: Color(0xFF4F46E5)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text('${_currencyFormat.format(item.custoUnitario)} / un', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 18),
                      onPressed: () {
                        setState(() {
                          if (item.quantidade > 1) {
                            _insumosAdicionados[idx] = InsumoCostItem(
                              insumoId: item.insumoId,
                              nome: item.nome,
                              custoUnitario: item.custoUnitario,
                              quantidade: item.quantidade - 1,
                            );
                          } else {
                            _insumosAdicionados.removeAt(idx);
                          }
                        });
                      },
                    ),
                    Text('${item.quantidade}x', style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      onPressed: () {
                        setState(() {
                          _insumosAdicionados[idx] = InsumoCostItem(
                            insumoId: item.insumoId,
                            nome: item.nome,
                            custoUnitario: item.custoUnitario,
                            quantidade: item.quantidade + 1,
                          );
                        });
                      },
                    ),
                    const SizedBox(width: 6),
                    Text(_currencyFormat.format(item.custoTotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      onPressed: () => setState(() => _insumosAdicionados.removeAt(idx)),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 18),

          // Mão de obra e Margens
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _tempoMaoDeObraController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Mão de Obra / Pós-processo (min)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Margem de Lucro: ${_margemLucro.toInt()}%'),
                    Slider(
                      value: _margemLucro,
                      min: 10,
                      max: 400,
                      divisions: 39,
                      onChanged: (val) => setState(() => _margemLucro = val),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final summaryPane = Container(
      color: const Color(0xFFF9FAFB),
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Resumo da Precificação',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            _ResumoRow(
              label: 'Filamentos (Peça)',
              valor: _currencyFormat.format(calc.custoFilamentosImpressos),
            ),
            _ResumoRow(
              label: 'Torre Purga & Flush (${_pesoPurgaController.text}g)',
              valor: _currencyFormat.format(calc.custoPurgaSuporte),
              isAlert: (double.tryParse(_pesoPurgaController.text) ?? 0) > 0,
            ),
            _ResumoRow(
              label: 'Insumos & Embalagens',
              valor: _currencyFormat.format(calc.custoInsumos),
            ),
            _ResumoRow(
              label: 'Energia Elétrica',
              valor: _currencyFormat.format(calc.custoEnergia),
            ),
            _ResumoRow(
              label: 'Depreciação + Manutenção',
              valor: _currencyFormat.format(calc.custoDepreciacaoManutencao),
            ),
            _ResumoRow(
              label: 'Mão de Obra',
              valor: _currencyFormat.format(calc.custoMaoDeObra),
            ),
            const Divider(),
            _ResumoRow(
              label: 'Custo Base Total',
              valor: _currencyFormat.format(calc.custoBaseTotal),
              isBold: true,
            ),
            _ResumoRow(
              label: 'Custo c/ Falha (${_taxaFalha.toInt()}%)',
              valor: _currencyFormat.format(calc.custoComMargemFalha),
            ),
            if (calc.tempoAdicionalTrocasMinutos > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '+${calc.tempoAdicionalTrocasMinutos} min pelas trocas no AMS (Total: ${calc.tempoTotalEfetivoMinutos} min)',
                  style: const TextStyle(fontSize: 12, color: Color(0xFFD97706)),
                ),
              ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFC7D2FE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Preço Venda Direta / Base',
                    style: TextStyle(color: Color(0xFF4F46E5), fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _currencyFormat.format(calc.precoVendaDiretaSugerido),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E1B4B),
                    ),
                  ),
                  Text(
                    'Lucro líquido: ${_currencyFormat.format(calc.lucroLiquidoEstimado)}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF059669)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Preço Final no Canal Selecionado (c/ Taxas & Imposto)',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _currencyFormat.format(calc.precoMarketplaceSugerido),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            ElevatedButton.icon(
              onPressed: () => _salvarComoOrcamento(calc),
              icon: const Icon(Icons.request_quote_rounded),
              label: const Text('Salvar como Orçamento'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _salvarNoCatalogoProdutos(calc),
              icon: const Icon(Icons.inventory_rounded),
              label: const Text('Salvar no Catálogo de Produtos'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4F46E5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Precificação & AMS Multicor'),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Recarregar dados do estoque',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _carregarDadosIniciais,
          ),
          IconButton(
            tooltip: 'Importar arquivo .3MF / GCODE',
            icon: const Icon(Icons.file_upload_rounded),
            onPressed: _selecionarArquivo3D,
          ),
        ],
      ),
      body: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: formPane),
                Expanded(flex: 4, child: summaryPane),
              ],
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  formPane,
                  summaryPane,
                ],
              ),
            ),
    );
  }
}

class _ResumoRow extends StatelessWidget {
  final String label;
  final String valor;
  final bool isBold;
  final bool isAlert;

  const _ResumoRow({
    required this.label,
    required this.valor,
    this.isBold = false,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: isAlert ? const Color(0xFFD97706) : const Color(0xFF4B5563),
                fontSize: 13,
              ),
            ),
          ),
          Text(
            valor,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isAlert ? const Color(0xFFD97706) : const Color(0xFF111827),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
