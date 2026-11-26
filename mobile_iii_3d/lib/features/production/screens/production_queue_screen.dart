import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../database/db_helper.dart';
import '../../damages/screens/damages_screen.dart';

class ProductionQueueScreen extends StatefulWidget {
  const ProductionQueueScreen({super.key});

  @override
  State<ProductionQueueScreen> createState() => _ProductionQueueScreenState();
}

class _ProductionQueueScreenState extends State<ProductionQueueScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  List<Map<String, dynamic>> _producoes = [];
  List<Map<String, dynamic>> _impressoras = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    final prods = await DbHelper.getAll('historico_producao');
    final imps = await DbHelper.getAll('impressoras');
    setState(() {
      _producoes = prods;
      _impressoras = imps;
      _isLoading = false;
    });
  }

  String _getNomeImpressora(String impressoraId) {
    final imp = _impressoras.firstWhere((i) => i['id'] == impressoraId, orElse: () => {});
    return imp['nome'] ?? 'Impressora Padrão';
  }

  Future<void> _iniciarImpressao(String id) async {
    final item = await DbHelper.getById('historico_producao', id);
    if (item == null) return;

    final updated = Map<String, dynamic>.from(item);
    updated['status'] = 'IMPRIMINDO';
    await DbHelper.update('historico_producao', updated, id);

    // Atualiza status na venda também
    final vendaId = item['vendaId'];
    if (vendaId != null) {
      final v = await DbHelper.getById('vendas', vendaId);
      if (v != null) {
        final upV = Map<String, dynamic>.from(v);
        upV['statusProducao'] = 'IMPRIMINDO';
        await DbHelper.update('vendas', upV, vendaId);
      }
    }

    await _carregarDados();
  }

  Future<void> _concluirComSucesso(Map<String, dynamic> item) async {
    final id = item['id'];
    final updated = Map<String, dynamic>.from(item);
    updated['status'] = 'SUCESSO';
    await DbHelper.update('historico_producao', updated, id);

    // Atualiza na venda
    final vendaId = item['vendaId'];
    if (vendaId != null) {
      final v = await DbHelper.getById('vendas', vendaId);
      if (v != null) {
        final upV = Map<String, dynamic>.from(v);
        upV['statusProducao'] = 'CONCLUIDO';
        upV['statusPagamento'] = 'PAGO';
        await DbHelper.update('vendas', upV, vendaId);

        // Registra entrada no caixa da venda
        final valor = (v['valorTotal'] as num?)?.toDouble() ?? 0.0;
        if (valor > 0) {
          await DbHelper.insert('movimentacoes_caixa', {
            'tipo': 'ENTRADA',
            'categoria': 'VENDA',
            'referenciaId': vendaId,
            'descricao': 'Recebimento Venda Concluída: ${v['codigoOrcamento']}',
            'valor': valor,
            'dataMovimentacao': DateTime.now().toIso8601String(),
            'status': 'PAGO',
          });
        }
      }
    }

    // Baixa automática de filamento do primeiro carretel se houver
    final filamentos = await DbHelper.getAll('filamentos');
    if (filamentos.isNotEmpty) {
      final primeiroFil = filamentos.first;
      await DbHelper.darBaixaEstoqueFilamento(
        filamentoId: primeiroFil['id'],
        pesoGramas: 60.0, // Baixa proporcional média
      );
    }

    await _carregarDados();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produção concluída com SUCESSO! Estoque baixado e caixa lançado.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _registrarFalha(Map<String, dynamic> item) async {
    final id = item['id'];
    final updated = Map<String, dynamic>.from(item);
    updated['status'] = 'FALHA';
    await DbHelper.update('historico_producao', updated, id);

    await _carregarDados();

    if (!mounted) return;

    // Oferece registrar na tela de Avarias
    final bool? abrirAvarias = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar Avaria / Desperdício?'),
        content: const Text(
          'Deseja registrar o material desperdiçado nesta falha de impressão no módulo de Avarias?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Não')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Registrar Avaria'),
          ),
        ],
      ),
    );

    if (abrirAvarias == true && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DamagesScreen()),
      );
      _carregarDados();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fila de Produção'),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _producoes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.precision_manufacturing_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        'Nenhuma ordem na fila de produção.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Aprove orçamentos na aba "Orçamentos" para enviar peças aqui.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _producoes.length,
                  itemBuilder: (context, index) {
                    final item = _producoes[index];
                    final status = item['status'] ?? 'AGUARDANDO_IMPRESSAO';
                    final nomeImp = _getNomeImpressora(item['impressoraId']);
                    final valor = (item['custoTotalProducao'] as num?)?.toDouble() ?? 0.0;

                    Color statusColor = const Color(0xFFD97706);
                    if (status == 'IMPRIMINDO') statusColor = const Color(0xFF2563EB);
                    if (status == 'SUCESSO') statusColor = const Color(0xFF10B981);
                    if (status == 'FALHA') statusColor = const Color(0xFFEF4444);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
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
                                  'Máquina: $nomeImp',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item['observacoes'] ?? 'Sem detalhes',
                              style: const TextStyle(color: Color(0xFF4B5563), fontSize: 13),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _currencyFormat.format(valor),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF4F46E5),
                                  ),
                                ),
                                Row(
                                  children: [
                                    if (status == 'AGUARDANDO_IMPRESSAO')
                                      ElevatedButton.icon(
                                        onPressed: () => _iniciarImpressao(item['id']),
                                        icon: const Icon(Icons.play_arrow_rounded, size: 18),
                                        label: const Text('Iniciar Impressão'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF2563EB),
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    if (status == 'IMPRIMINDO') ...[
                                      OutlinedButton.icon(
                                        onPressed: () => _registrarFalha(item),
                                        icon: const Icon(Icons.close_rounded, size: 16, color: Colors.red),
                                        label: const Text('Falha', style: TextStyle(color: Colors.red)),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        onPressed: () => _concluirComSucesso(item),
                                        icon: const Icon(Icons.check_circle_outline, size: 18),
                                        label: const Text('Confirmar Sucesso'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF10B981),
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
