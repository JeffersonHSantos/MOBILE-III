import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../database/db_helper.dart';
import '../../../widgets/barcode_scanner_modal.dart';
import '../../pricing/screens/pricing_calculator_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  List<Map<String, dynamic>> _produtos = [];
  String _busca = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarProdutos();
  }

  Future<void> _carregarProdutos() async {
    setState(() => _isLoading = true);
    final list = await DbHelper.getAll('produtos');
    if (mounted) {
      setState(() {
        _produtos = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _mostrarEtiquetaCodigoBarras(Map<String, dynamic> produto) async {
    final code = (produto['codigoBarrasProduto'] ?? '').toString().isNotEmpty
        ? produto['codigoBarrasProduto'].toString()
        : produto['id'].toString().substring(0, 8);
    final preco = (produto['precoVendaSugerido'] as num?)?.toDouble() ?? 0.0;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Etiqueta do Produto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(produto['nome'] ?? 'Produto', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            Text(_currencyFormat.format(preco), style: const TextStyle(fontSize: 18, color: Color(0xFF4F46E5), fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: BarcodeWidget(
                barcode: Barcode.code128(),
                data: code,
                width: 220,
                height: 80,
                drawText: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar')),
        ],
      ),
    );
  }

  Future<void> _ajustarEstoquePronto(Map<String, dynamic> produto, int delta) async {
    final atual = (produto['estoqueProntoUnidades'] as num?)?.toInt() ?? 0;
    final novo = (atual + delta).clamp(0, 999999);
    final updated = Map<String, dynamic>.from(produto);
    updated['estoqueProntoUnidades'] = novo;
    await DbHelper.update('produtos', updated, produto['id']);
    await _carregarProdutos();
  }

  Future<void> _abrirScanner() async {
    final codigo = await showBarcodeScannerModal(context);
    if (codigo != null && codigo.isNotEmpty) {
      setState(() => _busca = codigo);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _produtos.where((p) {
      if (_busca.isEmpty) return true;
      final q = _busca.toLowerCase();
      return (p['nome'] ?? '').toString().toLowerCase().contains(q) ||
          (p['codigoBarrasProduto'] ?? '').toString().toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Produtos'),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Ler código de barras',
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: _abrirScanner,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const PricingCalculatorScreen()));
          _carregarProdutos();
        },
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Novo Produto (via Precificação)'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: TextEditingController.fromValue(
                      TextEditingValue(text: _busca, selection: TextSelection.collapsed(offset: _busca.length)),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Buscar produto por nome ou código de barras...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.qr_code_scanner_rounded),
                        onPressed: _abrirScanner,
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (val) => setState(() => _busca = val),
                  ),
                ),
                Expanded(
                  child: filtrados.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.view_in_ar_outlined, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              const Text('Nenhum produto salvo no catálogo ainda.'),
                              const SizedBox(height: 6),
                              const Text(
                                'Use a Calculadora de Precificação e clique em "Salvar no Catálogo de Produtos".',
                                style: TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filtrados.length,
                          itemBuilder: (context, index) {
                            final p = filtrados[index];
                            final preco = (p['precoVendaSugerido'] as num?)?.toDouble() ?? 0.0;
                            final estoque = (p['estoqueProntoUnidades'] as num?)?.toInt() ?? 0;
                            final tempo = (p['tempoImpressaoMinutos'] as num?)?.toInt() ?? 0;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            p['nome'] ?? 'Produto',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                        ),
                                        Text(
                                          _currencyFormat.format(preco),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 18,
                                            color: Color(0xFF4F46E5),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Tempo: $tempo min | Cód: ${p['codigoBarrasProduto'] ?? '-'}',
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Text('Prateleira: ', style: TextStyle(fontWeight: FontWeight.w600)),
                                            IconButton(
                                              icon: const Icon(Icons.remove_circle_outline, size: 20),
                                              onPressed: () => _ajustarEstoquePronto(p, -1),
                                            ),
                                            Text('$estoque un', style: const TextStyle(fontWeight: FontWeight.bold)),
                                            IconButton(
                                              icon: const Icon(Icons.add_circle_outline, size: 20),
                                              onPressed: () => _ajustarEstoquePronto(p, 1),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            OutlinedButton.icon(
                                              onPressed: () => _mostrarEtiquetaCodigoBarras(p),
                                              icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                                              label: const Text('Etiqueta'),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                                              onPressed: () async {
                                                await DbHelper.delete('produtos', p['id']);
                                                await _carregarProdutos();
                                              },
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
                        ),
                ),
              ],
            ),
    );
  }
}
