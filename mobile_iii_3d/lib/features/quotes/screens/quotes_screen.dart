import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../database/db_helper.dart';
import '../../pricing/screens/pricing_calculator_screen.dart';

class QuotesScreen extends StatefulWidget {
  const QuotesScreen({super.key});

  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> with SingleTickerProviderStateMixin {
  final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  late TabController _tabController;
  List<Map<String, dynamic>> _vendas = [];
  List<Map<String, dynamic>> _clientes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _carregarDados();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    final vendas = await DbHelper.getAll('vendas');
    final clientes = await DbHelper.getAll('clientes');

    setState(() {
      _vendas = vendas;
      _clientes = clientes;
      _isLoading = false;
    });
  }

  String _getNomeCliente(String? clienteId) {
    if (clienteId == null) return 'Cliente Avulso / Balcão';
    final cli = _clientes.firstWhere((c) => c['id'] == clienteId, orElse: () => {});
    return cli['nome'] ?? 'Cliente Avulso';
  }

  Future<void> _atualizarStatusOrcamento(String orcamentoId, String novoStatus) async {
    final venda = await DbHelper.getById('vendas', orcamentoId);
    if (venda == null) return;

    final updated = Map<String, dynamic>.from(venda);
    updated['statusOrcamento'] = novoStatus;
    await DbHelper.update('vendas', updated, orcamentoId);

    await _carregarDados();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status do orçamento atualizado para: $novoStatus'),
          backgroundColor: novoStatus == 'APROVADO' ? const Color(0xFF10B981) : Colors.grey[800],
        ),
      );
    }
  }

  Future<void> _enviarParaProducao(Map<String, dynamic> orcamento) async {
    final orcamentoId = orcamento['id'];
    final updated = Map<String, dynamic>.from(orcamento);
    updated['statusProducao'] = 'AGUARDANDO_IMPRESSAO';
    await DbHelper.update('vendas', updated, orcamentoId);

    // Registra na fila de produção
    final imps = await DbHelper.getAll('impressoras');
    final defaultImpId = imps.isNotEmpty ? imps.first['id'] : 'imp_1';

    await DbHelper.insert('historico_producao', {
      'vendaId': orcamentoId,
      'produtoId': orcamento['id'],
      'impressoraId': defaultImpId,
      'dataProducao': DateTime.now().toIso8601String(),
      'quantidadeProduzida': 1,
      'status': 'AGUARDANDO_IMPRESSAO',
      'custoTotalProducao': orcamento['valorTotal'],
      'observacoes': orcamento['observacoes'] ?? 'Enviado da categoria de Aprovados',
    });

    await _carregarDados();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Orçamento aprovado enviado para a Fila de Produção!'),
          backgroundColor: Color(0xFF4F46E5),
        ),
      );
    }
  }

  List<Map<String, dynamic>> _filtrarPorStatus(String statusFiltro) {
    if (statusFiltro == 'TODOS') return _vendas;
    return _vendas.where((v) => (v['statusOrcamento'] ?? 'PENDENTE') == statusFiltro).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orçamentos de Impressão'),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Pendentes'),
            Tab(text: 'Aprovados'),
            Tab(text: 'Recusados'),
            Tab(text: 'Todos'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PricingCalculatorScreen()),
          );
          _carregarDados();
        },
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Novo Orçamento'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildListaOrcamentos(_filtrarPorStatus('PENDENTE')),
                _buildListaOrcamentos(_filtrarPorStatus('APROVADO')),
                _buildListaOrcamentos(_filtrarPorStatus('RECUSADO')),
                _buildListaOrcamentos(_filtrarPorStatus('TODOS')),
              ],
            ),
    );
  }

  Widget _buildListaOrcamentos(List<Map<String, dynamic>> lista) {
    if (lista.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'Nenhum orçamento encontrado nesta categoria.',
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lista.length,
      itemBuilder: (context, index) {
        final orc = lista[index];
        final statusOrc = orc['statusOrcamento'] ?? 'PENDENTE';
        final statusProd = orc['statusProducao'] ?? 'ORCAMENTO';
        final valor = (orc['valorTotal'] as num?)?.toDouble() ?? 0.0;
        final nomeCliente = _getNomeCliente(orc['clienteId']);

        Color badgeColor = const Color(0xFFD97706);
        if (statusOrc == 'APROVADO') badgeColor = const Color(0xFF10B981);
        if (statusOrc == 'RECUSADO') badgeColor = const Color(0xFFEF4444);

        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          elevation: 0,
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
                      orc['codigoOrcamento'] ?? 'ORC-#',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusOrc,
                        style: TextStyle(
                          color: badgeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Cliente: $nomeCliente',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                ),
                const SizedBox(height: 4),
                Text(
                  orc['observacoes'] ?? 'Sem detalhes',
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _currencyFormat.format(valor),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                    Row(
                      children: [
                        // Ações para Pendente
                        if (statusOrc == 'PENDENTE') ...[
                          OutlinedButton(
                            onPressed: () => _atualizarStatusOrcamento(orc['id'], 'RECUSADO'),
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('Recusar'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _atualizarStatusOrcamento(orc['id'], 'APROVADO'),
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Aprovar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],

                        // Ações para Aprovado (Requisito 4 do usuário)
                        if (statusOrc == 'APROVADO') ...[
                          if (statusProd == 'ORCAMENTO')
                            ElevatedButton.icon(
                              onPressed: () => _enviarParaProducao(orc),
                              icon: const Icon(Icons.print_rounded, size: 18),
                              label: const Text('Mandar para Produção'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                foregroundColor: Colors.white,
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Em Produção: $statusProd',
                                style: const TextStyle(
                                  color: Color(0xFF4F46E5),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
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
    );
  }
}
