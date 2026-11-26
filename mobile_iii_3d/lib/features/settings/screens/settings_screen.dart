import 'package:flutter/material.dart';
import '../../../database/db_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _kwhCtrl = TextEditingController();
  final _maoDeObraCtrl = TextEditingController();
  final _falhaCtrl = TextEditingController();
  final _margemCtrl = TextEditingController();
  final _impostoCtrl = TextEditingController();

  List<Map<String, dynamic>> _canais = [];
  List<Map<String, dynamic>> _formas = [];
  String _configId = 'config_default';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _kwhCtrl.dispose();
    _maoDeObraCtrl.dispose();
    _falhaCtrl.dispose();
    _margemCtrl.dispose();
    _impostoCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() => _isLoading = true);
    final configs = await DbHelper.getAll('configuracoes_gerais');
    final canais = await DbHelper.getAll('canais_venda');
    final formas = await DbHelper.getAll('formas_pagamento');

    if (configs.isNotEmpty) {
      final c = configs.first;
      _configId = c['id'] ?? 'config_default';
      _kwhCtrl.text = ((c['valorKwh'] as num?)?.toDouble() ?? 0.95).toStringAsFixed(2);
      _maoDeObraCtrl.text = ((c['valorHoraMaoDeObra'] as num?)?.toDouble() ?? 25.0).toStringAsFixed(2);
      _falhaCtrl.text = ((c['taxaFalhaPadraoPercentual'] as num?)?.toDouble() ?? 10.0).toStringAsFixed(1);
      _margemCtrl.text = ((c['margemLucroPadraoPercentual'] as num?)?.toDouble() ?? 100.0).toStringAsFixed(1);
      _impostoCtrl.text = ((c['taxaImpostoPercentual'] as num?)?.toDouble() ?? 6.0).toStringAsFixed(1);
    }

    if (mounted) {
      setState(() {
        _canais = canais;
        _formas = formas;
        _isLoading = false;
      });
    }
  }

  Future<void> _salvarConfigGeral() async {
    await DbHelper.update(
      'configuracoes_gerais',
      {
        'valorKwh': double.tryParse(_kwhCtrl.text.replaceAll(',', '.')) ?? 0.95,
        'valorHoraMaoDeObra': double.tryParse(_maoDeObraCtrl.text.replaceAll(',', '.')) ?? 25.0,
        'taxaFalhaPadraoPercentual': double.tryParse(_falhaCtrl.text.replaceAll(',', '.')) ?? 10.0,
        'margemLucroPadraoPercentual': double.tryParse(_margemCtrl.text.replaceAll(',', '.')) ?? 100.0,
        'taxaImpostoPercentual': double.tryParse(_impostoCtrl.text.replaceAll(',', '.')) ?? 6.0,
      },
      _configId,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configurações gerais salvas e aplicadas na precificação!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _adicionarCanalVenda() async {
    final nomeCtrl = TextEditingController();
    final comissaoCtrl = TextEditingController(text: '14.0');
    final fixaCtrl = TextEditingController(text: '4.0');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Novo Canal de Venda / Marketplace'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(controller: nomeCtrl, decoration: const InputDecoration(labelText: 'Nome (ex: TikTok Shop, Elo7)', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextFormField(controller: comissaoCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Comissão (%)', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextFormField(controller: fixaCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Taxa Fixa por Venda (R\$)', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nomeCtrl.text.trim().isEmpty) return;
              await DbHelper.insert('canais_venda', {
                'nome': nomeCtrl.text.trim(),
                'comissaoPercentual': double.tryParse(comissaoCtrl.text.replaceAll(',', '.')) ?? 0.0,
                'taxaFixaPorVenda': double.tryParse(fixaCtrl.text.replaceAll(',', '.')) ?? 0.0,
                'taxaAntecipacaoPercentual': 0.0,
              });
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              _carregar();
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _adicionarFormaPagamento() async {
    final nomeCtrl = TextEditingController();
    final taxaCtrl = TextEditingController(text: '4.5');
    final diasCtrl = TextEditingController(text: '30');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nova Forma de Pagamento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(controller: nomeCtrl, decoration: const InputDecoration(labelText: 'Nome (ex: Crédito 3x)', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextFormField(controller: taxaCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Taxa da Maquininha (%)', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextFormField(controller: diasCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Dias para cair', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nomeCtrl.text.trim().isEmpty) return;
              await DbHelper.insert('formas_pagamento', {
                'nome': nomeCtrl.text.trim(),
                'taxaPercentual': double.tryParse(taxaCtrl.text.replaceAll(',', '.')) ?? 0.0,
                'diasParaCair': int.tryParse(diasCtrl.text) ?? 0,
              });
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              _carregar();
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações & Taxas'),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Parâmetros Globais de Precificação', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _kwhCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Valor kWh (R\$)', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _maoDeObraCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Mão de Obra / Hora (R\$)', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _falhaCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Taxa de Falha (%)', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _margemCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Margem Padrão (%)', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _impostoCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Imposto MEI/SN (%)', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: _salvarConfigGeral,
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Salvar Parâmetros Gerais'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const Divider(height: 36),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Canais de Venda / Marketplaces', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      TextButton.icon(onPressed: _adicionarCanalVenda, icon: const Icon(Icons.add), label: const Text('Adicionar')),
                    ],
                  ),
                  ..._canais.map((c) => ListTile(
                        leading: const Icon(Icons.storefront_rounded, color: Color(0xFF4F46E5)),
                        title: Text(c['nome'] ?? ''),
                        subtitle: Text('Comissão: ${c['comissaoPercentual']}% | Taxa fixa: R\$ ${c['taxaFixaPorVenda']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () async {
                            await DbHelper.delete('canais_venda', c['id']);
                            _carregar();
                          },
                        ),
                      )),
                  const Divider(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Formas de Pagamento', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      TextButton.icon(onPressed: _adicionarFormaPagamento, icon: const Icon(Icons.add), label: const Text('Adicionar')),
                    ],
                  ),
                  ..._formas.map((f) => ListTile(
                        leading: const Icon(Icons.payments_outlined, color: Color(0xFF059669)),
                        title: Text(f['nome'] ?? ''),
                        subtitle: Text('Taxa: ${f['taxaPercentual']}% | Cai em ${f['diasParaCair']} dia(s)'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () async {
                            await DbHelper.delete('formas_pagamento', f['id']);
                            _carregar();
                          },
                        ),
                      )),
                ],
              ),
            ),
    );
  }
}
