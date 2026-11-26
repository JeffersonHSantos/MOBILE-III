import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../database/db_helper.dart';

class DamagesScreen extends StatefulWidget {
  const DamagesScreen({super.key});

  @override
  State<DamagesScreen> createState() => _DamagesScreenState();
}

class _DamagesScreenState extends State<DamagesScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  List<Map<String, dynamic>> _avarias = [];
  List<Map<String, dynamic>> _filamentos = [];
  List<Map<String, dynamic>> _insumos = [];
  List<Map<String, dynamic>> _produtos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    final avs = await DbHelper.getAll('avarias');
    final fils = await DbHelper.getAll('filamentos');
    final ins = await DbHelper.getAll('insumos');
    final prods = await DbHelper.getAll('produtos');

    setState(() {
      _avarias = avs;
      _filamentos = fils;
      _insumos = ins;
      _produtos = prods;
      _isLoading = false;
    });
  }

  double _calcularTotalPrejuizo() {
    double total = 0.0;
    for (final a in _avarias) {
      total += (a['custoEstimadoPerda'] as num?)?.toDouble() ?? 0.0;
    }
    return total;
  }

  // ==========================================
  // MODAL PARA REGISTRAR NOVA AVARIA
  // ==========================================
  Future<void> _abrirModalNovaAvaria() async {
    String tipoSelecionado = 'FILAMENTO'; // 'FILAMENTO', 'INSUMO', 'PRODUTO'
    String? itemIdSelecionado;
    final qtdController = TextEditingController(text: '50');
    final motivoController = TextEditingController(text: 'Falha de impressão / clog');
    final obsController = TextEditingController();

    if (_filamentos.isNotEmpty) {
      itemIdSelecionado = _filamentos.first['id'];
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            // Obter nome e calcular custo estimado
            double custoEstimado = 0.0;
            String unidade = 'g';
            String itemNome = 'Item Selecionado';

            final qtd = double.tryParse(qtdController.text) ?? 0.0;

            if (tipoSelecionado == 'FILAMENTO') {
              unidade = 'g';
              final fil = _filamentos.firstWhere(
                (f) => f['id'] == itemIdSelecionado,
                orElse: () => {},
              );
              if (fil.isNotEmpty) {
                itemNome = '${fil['marca']} ${fil['material']} ${fil['corNome']}';
                final precoKg = (fil['precoPago'] as num?)?.toDouble() ?? 100.0;
                custoEstimado = qtd * (precoKg / 1000.0);
              }
            } else if (tipoSelecionado == 'INSUMO') {
              unidade = 'un';
              final ins = _insumos.firstWhere(
                (i) => i['id'] == itemIdSelecionado,
                orElse: () => {},
              );
              if (ins.isNotEmpty) {
                itemNome = ins['nome'] ?? '';
                final precoPct = (ins['precoPacotePago'] as num?)?.toDouble() ?? 30.0;
                final qtdPct = (ins['quantidadeComprada'] as num?)?.toInt() ?? 50;
                final custoUnit = qtdPct > 0 ? (precoPct / qtdPct) : 1.0;
                custoEstimado = qtd * custoUnit;
              }
            } else {
              unidade = 'peças';
              final prod = _produtos.firstWhere(
                (p) => p['id'] == itemIdSelecionado,
                orElse: () => {},
              );
              if (prod.isNotEmpty) {
                itemNome = prod['nome'] ?? '';
                custoEstimado = qtd * 15.0; // estimativa
              }
            }

            return AlertDialog(
              title: const Text('Registrar Avaria / Baixa por Perda'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Categoria do item com avaria:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'FILAMENTO', label: Text('Filamento')),
                        ButtonSegment(value: 'INSUMO', label: Text('Insumo')),
                        ButtonSegment(value: 'PRODUTO', label: Text('Peça')),
                      ],
                      selected: {tipoSelecionado},
                      onSelectionChanged: (val) {
                        setDlgState(() {
                          tipoSelecionado = val.first;
                          if (tipoSelecionado == 'FILAMENTO' && _filamentos.isNotEmpty) {
                            itemIdSelecionado = _filamentos.first['id'];
                            qtdController.text = '50';
                          } else if (tipoSelecionado == 'INSUMO' && _insumos.isNotEmpty) {
                            itemIdSelecionado = _insumos.first['id'];
                            qtdController.text = '2';
                          } else if (_produtos.isNotEmpty) {
                            itemIdSelecionado = _produtos.first['id'];
                            qtdController.text = '1';
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 14),

                    // Seleção do Item específico
                    if (tipoSelecionado == 'FILAMENTO')
                      DropdownButtonFormField<String>(
                        value: itemIdSelecionado,
                        decoration: const InputDecoration(labelText: 'Carretel de Filamento', border: OutlineInputBorder()),
                        items: _filamentos.map((f) {
                          return DropdownMenuItem<String>(
                            value: f['id'],
                            child: Text('${f['corNome']} (${f['material']} - Saldo: ${f['pesoAtualGramas']}g)'),
                          );
                        }).toList(),
                        onChanged: (val) => setDlgState(() => itemIdSelecionado = val),
                      ),
                    if (tipoSelecionado == 'INSUMO')
                      DropdownButtonFormField<String>(
                        value: itemIdSelecionado,
                        decoration: const InputDecoration(labelText: 'Insumo / Embalagem', border: OutlineInputBorder()),
                        items: _insumos.map((i) {
                          return DropdownMenuItem<String>(
                            value: i['id'],
                            child: Text('${i['nome']} (Saldo: ${i['quantidadeAtual']} un)'),
                          );
                        }).toList(),
                        onChanged: (val) => setDlgState(() => itemIdSelecionado = val),
                      ),

                    const SizedBox(height: 12),

                    // Quantidade perdida
                    TextFormField(
                      controller: qtdController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Quantidade Perdida ($unidade)',
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) => setDlgState(() {}),
                    ),
                    const SizedBox(height: 12),

                    // Motivo
                    TextFormField(
                      controller: motivoController,
                      decoration: const InputDecoration(
                        labelText: 'Motivo da Perda / Avaria',
                        hintText: 'Ex: Carretel embolou, umidade, deslocou camada...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Prejuízo estimado calculado
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Custo Estimado da Perda:', style: TextStyle(color: Color(0xFF991B1B))),
                          Text(
                            _currencyFormat.format(custoEstimado),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                          ),
                        ],
                      ),
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
                    if (itemIdSelecionado == null || qtd <= 0) return;

                    await DbHelper.registrarAvaria(
                      tipoItem: tipoSelecionado,
                      itemId: itemIdSelecionado!,
                      itemNome: itemNome,
                      quantidadePerdida: qtd,
                      unidade: unidade,
                      custoEstimadoPerda: custoEstimado,
                      motivo: motivoController.text,
                      observacoes: obsController.text,
                    );

                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    await _carregarDados();

                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Avaria registrada com sucesso! Baixa de $qtd$unidade efetuada no estoque.'),
                        backgroundColor: const Color(0xFFDC2626),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
                  child: const Text('Confirmar Baixa por Avaria'),
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
    final totalPrejuizo = _calcularTotalPrejuizo();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão de Avarias e Perdas'),
        backgroundColor: const Color(0xFFDC2626),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirModalNovaAvaria,
        backgroundColor: const Color(0xFFDC2626),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.warning_amber_rounded),
        label: const Text('Registrar Avaria'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Card Resumo de Prejuízos Acumulados
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.trending_down_rounded, color: Color(0xFFDC2626), size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total de Prejuízo Acumulado (Avarias)',
                              style: TextStyle(color: Color(0xFF991B1B), fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currencyFormat.format(totalPrejuizo),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF7F1D1D),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${_avarias.length} ocorrência(s)',
                        style: const TextStyle(color: Color(0xFFB91C1C), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),

                // Lista de Avarias
                Expanded(
                  child: _avarias.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.verified_rounded, size: 64, color: Colors.green[300]),
                              const SizedBox(height: 12),
                              Text(
                                'Nenhuma avaria registrada. Operação 100% eficiente!',
                                style: TextStyle(color: Colors.grey[600], fontSize: 15),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _avarias.length,
                          itemBuilder: (context, index) {
                            final av = _avarias[index];
                            final tipo = av['tipoItem'] ?? 'FILAMENTO';
                            final itemNome = av['itemNome'] ?? 'Item';
                            final qtd = (av['quantidadePerdida'] as num?)?.toDouble() ?? 0.0;
                            final unidade = av['unidade'] ?? 'g';
                            final custo = (av['custoEstimadoPerda'] as num?)?.toDouble() ?? 0.0;
                            final motivo = av['motivo'] ?? 'Sem motivo informado';
                            final dataStr = av['dataAvaria'] != null
                                ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(av['dataAvaria']))
                                : '';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: const BorderSide(color: Color(0xFFFEE2E2)),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFFFEE2E2),
                                  child: Icon(
                                    tipo == 'FILAMENTO'
                                        ? Icons.album_rounded
                                        : tipo == 'INSUMO'
                                            ? Icons.inventory_2_rounded
                                            : Icons.view_in_ar_rounded,
                                    color: const Color(0xFFDC2626),
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  itemNome,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('Perda: $qtd$unidade | Motivo: $motivo'),
                                    if (dataStr.isNotEmpty)
                                      Text(dataStr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                                trailing: Text(
                                  _currencyFormat.format(custo),
                                  style: const TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
