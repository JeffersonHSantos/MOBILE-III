import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../database/db_helper.dart';
import '../../../widgets/barcode_scanner_modal.dart';

class FilamentsScreen extends StatefulWidget {
  final int initialTabIndex;

  const FilamentsScreen({super.key, this.initialTabIndex = 0});

  @override
  State<FilamentsScreen> createState() => _FilamentsScreenState();
}

class _FilamentsScreenState extends State<FilamentsScreen> with SingleTickerProviderStateMixin {
  final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  late TabController _tabController;
  List<Map<String, dynamic>> _filamentos = [];
  List<Map<String, dynamic>> _insumos = [];
  List<Map<String, dynamic>> _impressoras = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _carregarDados();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    final fils = await DbHelper.getAll('filamentos');
    final ins = await DbHelper.getAll('insumos');
    final imps = await DbHelper.getAll('impressoras');
    setState(() {
      _filamentos = fils;
      _insumos = ins;
      _impressoras = imps;
      _isLoading = false;
    });
  }

  // ==========================================
  // MODAL CADASTRO: FILAMENTO
  // ==========================================
  Future<void> _adicionarNovoFilamento() async {
    final marcaCtrl = TextEditingController(text: 'Bambu Lab');
    final matCtrl = TextEditingController(text: 'PLA Basic');
    final corCtrl = TextEditingController(text: 'Preto');
    final pesoInicialCtrl = TextEditingController(text: '1000');
    final precoCtrl = TextEditingController(text: '120.00');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cadastrar Novo Carretel'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: marcaCtrl, decoration: const InputDecoration(labelText: 'Marca')),
              const SizedBox(height: 8),
              TextFormField(controller: matCtrl, decoration: const InputDecoration(labelText: 'Material (PLA, PETG, TPU...)')),
              const SizedBox(height: 8),
              TextFormField(controller: corCtrl, decoration: const InputDecoration(labelText: 'Nome da Cor')),
              const SizedBox(height: 8),
              TextFormField(controller: pesoInicialCtrl, decoration: const InputDecoration(labelText: 'Peso Inicial (g)'), keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              TextFormField(controller: precoCtrl, decoration: const InputDecoration(labelText: 'Preço Pago (R\$)'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final peso = double.tryParse(pesoInicialCtrl.text) ?? 1000.0;
              final preco = double.tryParse(precoCtrl.text) ?? 100.0;
              await DbHelper.insert('filamentos', {
                'marca': marcaCtrl.text,
                'material': matCtrl.text,
                'corNome': corCtrl.text,
                'corHex': '#111827',
                'pesoInicialGramas': peso,
                'pesoAtualGramas': peso,
                'precoPago': preco,
                'alertaEstoqueMinimoGramas': 150.0,
              });
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              await _carregarDados();
            },
            child: const Text('Salvar Carretel'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MODAL CADASTRO: INSUMO
  // ==========================================
  Future<void> _adicionarNovoInsumo() async {
    final nomeCtrl = TextEditingController(text: 'Argola de Chaveiro 25mm');
    String categoria = 'ACESSORIO';
    final qtdCtrl = TextEditingController(text: '100');
    final precoCtrl = TextEditingController(text: '25.00');

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Cadastrar Insumo / Embalagem'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: nomeCtrl, decoration: const InputDecoration(labelText: 'Nome do Insumo')),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: categoria,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                  items: const [
                    DropdownMenuItem(value: 'ACESSORIO', child: Text('Acessório (Ímã, argola, parafuso...)')),
                    DropdownMenuItem(value: 'EMBALAGEM', child: Text('Embalagem (Caixa, saco bolha, fita...)')),
                  ],
                  onChanged: (val) => setDlgState(() => categoria = val ?? 'ACESSORIO'),
                ),
                const SizedBox(height: 10),
                TextFormField(controller: qtdCtrl, decoration: const InputDecoration(labelText: 'Quantidade Comprada'), keyboardType: TextInputType.number),
                const SizedBox(height: 10),
                TextFormField(controller: precoCtrl, decoration: const InputDecoration(labelText: 'Preço Total Pago (R\$)'), keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                final qtd = int.tryParse(qtdCtrl.text) ?? 50;
                final preco = double.tryParse(precoCtrl.text) ?? 20.0;
                await DbHelper.insert('insumos', {
                  'nome': nomeCtrl.text,
                  'categoria': categoria,
                  'quantidadeComprada': qtd,
                  'quantidadeAtual': qtd,
                  'precoPacotePago': preco,
                });
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                await _carregarDados();
              },
              child: const Text('Salvar Insumo'),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // MODAL CADASTRO: IMPRESSORA (REQUISITO EXPLÍCITO)
  // ==========================================
  Future<void> _adicionarNovaImpressora() async {
    final nomeCtrl = TextEditingController(text: 'Bambu Lab P1S');
    final potenciaCtrl = TextEditingController(text: '160');
    final valorAquisicaoCtrl = TextEditingController(text: '3900.00');
    final vidaUtilCtrl = TextEditingController(text: '4000');
    final manutencaoCtrl = TextEditingController(text: '0.85');
    final fornecedorCtrl = TextEditingController(text: 'Loja Oficial');
    final obsCtrl = TextEditingController(text: 'Equipada com AMS');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cadastrar Nova Impressora 3D'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nomeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Modelo / Nome da Impressora',
                  hintText: 'Ex: Bambu Lab A1, Ender 3, K1 Max...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: potenciaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Potência Média (Watts)',
                        hintText: 'Ex: 150',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: valorAquisicaoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Preço Pago (R\$)',
                        hintText: 'Ex: 2500.00',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: vidaUtilCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Vida Útil Estimada (Horas)',
                        hintText: 'Ex: 3000',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: manutencaoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Manutenção por Hora (R\$)',
                        hintText: 'Ex: 0.80',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: fornecedorCtrl,
                decoration: const InputDecoration(
                  labelText: 'Fornecedor / Onde Comprou',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: obsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Observações (AMS, Bico 0.4mm, etc.)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final potencia = int.tryParse(potenciaCtrl.text) ?? 150;
              final valorAq = double.tryParse(valorAquisicaoCtrl.text) ?? 2500.0;
              final vidaUtil = int.tryParse(vidaUtilCtrl.text) ?? 3000;
              final manutencao = double.tryParse(manutencaoCtrl.text) ?? 0.80;

              await DbHelper.insert('impressoras', {
                'nome': nomeCtrl.text,
                'potenciaWatts': potencia,
                'valorAquisicao': valorAq,
                'vidaUtilHoras': vidaUtil,
                'custoManutencaoHora': manutencao,
                'fornecedorOndeComprou': fornecedorCtrl.text,
                'observacoes': obsCtrl.text,
              });

              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              await _carregarDados();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Impressora "${nomeCtrl.text}" cadastrada com sucesso!'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
            ),
            child: const Text('Salvar Impressora'),
          ),
        ],
      ),
    );
  }

  void _onFabPressed() {
    switch (_tabController.index) {
      case 0:
        _adicionarNovoFilamento();
        break;
      case 1:
        _adicionarNovoInsumo();
        break;
      case 2:
        _adicionarNovaImpressora();
        break;
    }
  }

  String _getFabLabel() {
    switch (_tabController.index) {
      case 0:
        return 'Novo Carretel';
      case 1:
        return 'Novo Insumo';
      case 2:
        return 'Nova Impressora';
      default:
        return 'Adicionar';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estoque & Equipamentos'),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Bipar código de barras',
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: () async {
              final code = await showBarcodeScannerModal(context);
              if (code != null && code.isNotEmpty && context.mounted) {
                final foundFil = _filamentos.where((f) => f['codigoBarrasEan'] == code).toList();
                final foundIns = _insumos.where((i) => i['codigoBarrasEan'] == code).toList();
                final msg = foundFil.isNotEmpty
                    ? 'Filamento encontrado: ${foundFil.first['marca']} ${foundFil.first['corNome']} (${foundFil.first['pesoAtualGramas']}g)'
                    : foundIns.isNotEmpty
                        ? 'Insumo encontrado: ${foundIns.first['nome']} (${foundIns.first['quantidadeAtual']} un)'
                        : 'Nenhum item com o código "$code" no estoque.';
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Filamentos'),
            Tab(text: 'Insumos'),
            Tab(text: 'Impressoras 3D'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onFabPressed,
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(_getFabLabel()),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildListaFilamentos(),
                _buildListaInsumos(),
                _buildListaImpressoras(),
              ],
            ),
    );
  }

  Widget _buildListaFilamentos() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filamentos.length,
      itemBuilder: (context, index) {
        final f = _filamentos[index];
        final pesoInicial = (f['pesoInicialGramas'] as num?)?.toDouble() ?? 1000.0;
        final pesoAtual = (f['pesoAtualGramas'] as num?)?.toDouble() ?? 0.0;
        final preco = (f['precoPago'] as num?)?.toDouble() ?? 100.0;
        final alertaMin = (f['alertaEstoqueMinimoGramas'] as num?)?.toDouble() ?? 150.0;

        final percent = (pesoAtual / pesoInicial).clamp(0.0, 1.0);
        final isBaixo = pesoAtual <= alertaMin;
        final custoGrama = pesoInicial > 0 ? (preco / pesoInicial) : 0.10;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: isBaixo ? Colors.red : const Color(0xFFE5E7EB)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${f['corNome']} • ${f['material']}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    if (isBaixo)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12)),
                        child: const Text('Estoque Baixo!', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                Text('${f['marca']} | Custo: ${_currencyFormat.format(custoGrama)} / grama', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: percent,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                  backgroundColor: const Color(0xFFEEF2FF),
                  color: isBaixo ? Colors.red : const Color(0xFF4F46E5),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Saldo: ${pesoAtual.toStringAsFixed(1)}g / ${pesoInicial.toInt()}g', style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('${(percent * 100).toInt()}% restante', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildListaInsumos() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _insumos.length,
      itemBuilder: (context, index) {
        final ins = _insumos[index];
        final qtdAtual = (ins['quantidadeAtual'] as num?)?.toInt() ?? 0;
        final preco = (ins['precoPacotePago'] as num?)?.toDouble() ?? 0.0;
        final qtdComp = (ins['quantidadeComprada'] as num?)?.toInt() ?? 1;
        final custoUnit = qtdComp > 0 ? (preco / qtdComp) : 0.0;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFEEF2FF),
              child: Icon(Icons.inventory_2_rounded, color: Color(0xFF4F46E5)),
            ),
            title: Text(ins['nome'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Categoria: ${ins['categoria']} | Custo Unitário: ${_currencyFormat.format(custoUnit)}'),
            trailing: Text('$qtdAtual un', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
          ),
        );
      },
    );
  }

  Widget _buildListaImpressoras() {
    if (_impressoras.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.precision_manufacturing_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text('Nenhuma impressora 3D cadastrada.'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _adicionarNovaImpressora,
              child: const Text('Cadastrar Primeira Impressora'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _impressoras.length,
      itemBuilder: (context, index) {
        final imp = _impressoras[index];
        final potencia = (imp['potenciaWatts'] as num?)?.toInt() ?? 150;
        final valorAq = (imp['valorAquisicao'] as num?)?.toDouble() ?? 2500.0;
        final vidaUtil = (imp['vidaUtilHoras'] as num?)?.toInt() ?? 3000;
        final manutencao = (imp['custoManutencaoHora'] as num?)?.toDouble() ?? 0.80;

        final amortizacaoHora = vidaUtil > 0 ? (valorAq / vidaUtil) : 0.0;
        final custoHoraTotal = amortizacaoHora + manutencao;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      imp['nome'] ?? 'Impressora',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$potencia Watts',
                        style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                if ((imp['observacoes'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    imp['observacoes'],
                    style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Valor de Aquisição', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        Text(_currencyFormat.format(valorAq), style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Vida Útil', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        Text('$vidaUtil horas', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Custo Total / Hora', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        Text(
                          '${_currencyFormat.format(custoHoraTotal)}/h',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5), fontSize: 15),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
