import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../database/db_helper.dart';

class PrintersScreen extends StatefulWidget {
  const PrintersScreen({super.key});

  @override
  State<PrintersScreen> createState() => _PrintersScreenState();
}

class _PrintersScreenState extends State<PrintersScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  List<Map<String, dynamic>> _impressoras = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarImpressoras();
  }

  Future<void> _carregarImpressoras() async {
    setState(() => _isLoading = true);
    final imps = await DbHelper.getAll('impressoras');
    setState(() {
      _impressoras = imps;
      _isLoading = false;
    });
  }

  Future<void> _abrirModalNovaImpressora([Map<String, dynamic>? impressoraExistente]) async {
    final isEdicao = impressoraExistente != null;
    final nomeCtrl = TextEditingController(text: impressoraExistente?['nome'] ?? 'Bambu Lab P1S');
    final potenciaCtrl = TextEditingController(
      text: (impressoraExistente?['potenciaWatts'] ?? 160).toString(),
    );
    final valorAquisicaoCtrl = TextEditingController(
      text: ((impressoraExistente?['valorAquisicao'] as num?)?.toDouble() ?? 3900.0).toStringAsFixed(2),
    );
    final vidaUtilCtrl = TextEditingController(
      text: (impressoraExistente?['vidaUtilHoras'] ?? 4000).toString(),
    );
    final manutencaoCtrl = TextEditingController(
      text: ((impressoraExistente?['custoManutencaoHora'] as num?)?.toDouble() ?? 0.85).toStringAsFixed(2),
    );
    final fornecedorCtrl = TextEditingController(
      text: impressoraExistente?['fornecedorOndeComprou'] ?? 'Loja Oficial',
    );
    final linkCtrl = TextEditingController(
      text: impressoraExistente?['linkCompra'] ?? '',
    );
    final obsCtrl = TextEditingController(
      text: impressoraExistente?['observacoes'] ?? 'Equipada com AMS de 4 cores',
    );

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdicao ? 'Editar Impressora 3D' : 'Cadastrar Nova Impressora 3D'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: nomeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Modelo / Nome da Impressora',
                  hintText: 'Ex: Bambu Lab A1, Ender 3, K1 Max...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.precision_manufacturing_rounded),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: potenciaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Potência Média (Watts)',
                        hintText: 'Ex: 150',
                        border: OutlineInputBorder(),
                        suffixText: 'W',
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: vidaUtilCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Vida Útil (Horas)',
                        hintText: 'Ex: 3000',
                        border: OutlineInputBorder(),
                        suffixText: 'h',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: manutencaoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Manutenção / Hora',
                        hintText: 'Ex: 0.80',
                        border: OutlineInputBorder(),
                        prefixText: 'R\$ ',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: fornecedorCtrl,
                decoration: const InputDecoration(
                  labelText: 'Fornecedor / Onde Comprou',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.storefront_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: linkCtrl,
                decoration: const InputDecoration(
                  labelText: 'Link de Compra / Peças (Opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: obsCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Observações (AMS, Bico 0.4mm, Câmera...)',
                  border: OutlineInputBorder(),
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
          ElevatedButton.icon(
            onPressed: () async {
              final potencia = int.tryParse(potenciaCtrl.text) ?? 150;
              final valorAq = double.tryParse(valorAquisicaoCtrl.text) ?? 2500.0;
              final vidaUtil = int.tryParse(vidaUtilCtrl.text) ?? 3000;
              final manutencao = double.tryParse(manutencaoCtrl.text) ?? 0.80;

              final data = {
                'nome': nomeCtrl.text.trim().isEmpty ? 'Impressora 3D' : nomeCtrl.text.trim(),
                'potenciaWatts': potencia,
                'valorAquisicao': valorAq,
                'vidaUtilHoras': vidaUtil,
                'custoManutencaoHora': manutencao,
                'fornecedorOndeComprou': fornecedorCtrl.text,
                'linkCompra': linkCtrl.text,
                'observacoes': obsCtrl.text,
              };

              if (isEdicao) {
                await DbHelper.update('impressoras', data, impressoraExistente['id']);
              } else {
                await DbHelper.insert('impressoras', data);
              }

              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              await _carregarImpressoras();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEdicao
                          ? 'Impressora atualizada com sucesso!'
                          : 'Impressora "${data['nome']}" cadastrada com sucesso!',
                    ),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              }
            },
            icon: const Icon(Icons.check_rounded),
            label: Text(isEdicao ? 'Salvar Alterações' : 'Cadastrar Impressora'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _excluirImpressora(String id, String nome) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Impressora?'),
        content: Text('Deseja realmente remover "$nome" do cadastro?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DbHelper.delete('impressoras', id);
      await _carregarImpressoras();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impressora "$nome" removida.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impressoras 3D & Máquinas'),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirModalNovaImpressora(),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nova Impressora'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _impressoras.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.precision_manufacturing_outlined, size: 72, color: Colors.grey[400]),
                      const SizedBox(height: 14),
                      const Text(
                        'Nenhuma impressora 3D cadastrada.',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Cadastre suas impressoras para calcular energia e custo/hora nas precificações.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _abrirModalNovaImpressora(),
                        icon: const Icon(Icons.add),
                        label: const Text('Cadastrar Primeira Impressora'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
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
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEEF2FF),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.precision_manufacturing_rounded,
                                        color: Color(0xFF4F46E5),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      imp['nome'] ?? 'Impressora',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEEF2FF),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '$potencia Watts',
                                        style: const TextStyle(
                                          color: Color(0xFF4F46E5),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.grey),
                                      onPressed: () => _abrirModalNovaImpressora(imp),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                      onPressed: () => _excluirImpressora(imp['id'], imp['nome']),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if ((imp['observacoes'] ?? '').toString().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                imp['observacoes'],
                                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                              ),
                            ],
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Valor Aquisição', style: TextStyle(color: Colors.grey, fontSize: 11)),
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
                                      const Text('Manutenção/h', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                      Text(_currencyFormat.format(manutencao), style: const TextStyle(fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Custo Total / Hora', style: TextStyle(color: Color(0xFF4F46E5), fontSize: 11, fontWeight: FontWeight.bold)),
                                      Text(
                                        '${_currencyFormat.format(custoHoraTotal)}/h',
                                        style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF4F46E5), fontSize: 15),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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
