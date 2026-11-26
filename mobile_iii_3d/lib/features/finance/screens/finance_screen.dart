import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../database/db_helper.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  List<Map<String, dynamic>> _movimentacoes = [];
  List<Map<String, dynamic>> _impressoras = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _isLoading = true);
    final movs = await DbHelper.getAll('movimentacoes_caixa');
    final imps = await DbHelper.getAll('impressoras');
    if (mounted) {
      setState(() {
        _movimentacoes = movs.reversed.toList();
        _impressoras = imps;
        _isLoading = false;
      });
    }
  }

  Future<void> _novaMovimentacao() async {
    String tipo = 'ENTRADA';
    String categoria = 'OUTROS';
    final descCtrl = TextEditingController();
    final valorCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Novo Lançamento no Caixa'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: tipo,
                decoration: const InputDecoration(labelText: 'Tipo', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'ENTRADA', child: Text('Entrada (Receita)')),
                  DropdownMenuItem(value: 'SAIDA_ESTOQUE', child: Text('Saída - Compra de Estoque')),
                  DropdownMenuItem(value: 'SAIDA_INVESTIMENTO', child: Text('Saída - Investimento / Máquina')),
                  DropdownMenuItem(value: 'SAIDA_DESPESA', child: Text('Saída - Despesa Geral')),
                ],
                onChanged: (v) => setDlgState(() => tipo = v ?? 'ENTRADA'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: categoria,
                decoration: const InputDecoration(labelText: 'Categoria', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'VENDA', child: Text('Venda')),
                  DropdownMenuItem(value: 'FILAMENTO', child: Text('Filamento')),
                  DropdownMenuItem(value: 'INSUMO', child: Text('Insumo')),
                  DropdownMenuItem(value: 'IMPRESSORA', child: Text('Impressora')),
                  DropdownMenuItem(value: 'MANUTENCAO', child: Text('Manutenção')),
                  DropdownMenuItem(value: 'OUTROS', child: Text('Outros')),
                ],
                onChanged: (v) => setDlgState(() => categoria = v ?? 'OUTROS'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Descrição', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: valorCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Valor (R\$)', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                final val = double.tryParse(valorCtrl.text.replaceAll(',', '.')) ?? 0.0;
                if (descCtrl.text.trim().isEmpty || val <= 0) return;

                await DbHelper.insert('movimentacoes_caixa', {
                  'tipo': tipo,
                  'categoria': categoria,
                  'descricao': descCtrl.text.trim(),
                  'valor': val,
                  'dataMovimentacao': DateTime.now().toIso8601String(),
                  'status': 'PAGO',
                });
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                _carregar();
              },
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalEntradas = 0.0;
    double totalSaidas = 0.0;

    for (final m in _movimentacoes) {
      final v = (m['valor'] as num?)?.toDouble() ?? 0.0;
      if (m['tipo'] == 'ENTRADA') {
        totalEntradas += v;
      } else {
        totalSaidas += v;
      }
    }

    final saldo = totalEntradas - totalSaidas;
    double investimentoMaquinas = 0.0;
    for (final imp in _impressoras) {
      investimentoMaquinas += (imp['valorAquisicao'] as num?)?.toDouble() ?? 0.0;
    }

    final paybackPercent = investimentoMaquinas > 0
        ? ((totalEntradas / investimentoMaquinas) * 100).clamp(0.0, 100.0)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financeiro, Caixa & ROI'),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _novaMovimentacao,
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Lançamento'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _FinanceSummaryCard(
                              title: 'Entradas',
                              value: _currencyFormat.format(totalEntradas),
                              color: const Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _FinanceSummaryCard(
                              title: 'Saídas / Perdas',
                              value: _currencyFormat.format(totalSaidas),
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _FinanceSummaryCard(
                              title: 'Saldo Caixa',
                              value: _currencyFormat.format(saldo),
                              color: saldo >= 0 ? const Color(0xFF4F46E5) : const Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Payback / ROI das Impressoras', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
                                Text('${paybackPercent.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
                              ],
                            ),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: paybackPercent / 100,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Receita bruta ${_currencyFormat.format(totalEntradas)} vs Investimento ${_currencyFormat.format(investimentoMaquinas)}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _movimentacoes.isEmpty
                      ? const Center(child: Text('Nenhuma movimentação registrada ainda.'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _movimentacoes.length,
                          itemBuilder: (context, index) {
                            final m = _movimentacoes[index];
                            final isEntrada = m['tipo'] == 'ENTRADA';
                            final val = (m['valor'] as num?)?.toDouble() ?? 0.0;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isEntrada ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                  child: Icon(
                                    isEntrada ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                    color: isEntrada ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                  ),
                                ),
                                title: Text(m['descricao'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text('${m['categoria']} • ${m['status']}'),
                                trailing: Text(
                                  '${isEntrada ? "+" : "-"} ${_currencyFormat.format(val)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isEntrada ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
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

class _FinanceSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _FinanceSummaryCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          ),
        ],
      ),
    );
  }
}
