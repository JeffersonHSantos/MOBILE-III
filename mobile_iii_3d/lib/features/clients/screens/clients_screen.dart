import 'package:flutter/material.dart';
import '../../../database/db_helper.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  List<Map<String, dynamic>> _clientes = [];
  String _busca = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarClientes();
  }

  Future<void> _carregarClientes() async {
    setState(() => _isLoading = true);
    final list = await DbHelper.getAll('clientes');
    if (mounted) {
      setState(() {
        _clientes = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _abrirModalCliente([Map<String, dynamic>? cliente]) async {
    final isEdicao = cliente != null;
    final nomeCtrl = TextEditingController(text: cliente?['nome'] ?? '');
    final zapCtrl = TextEditingController(text: cliente?['telefoneWhatsapp'] ?? '');
    final emailCtrl = TextEditingController(text: cliente?['email'] ?? '');
    final cpfCtrl = TextEditingController(text: cliente?['cpfCnpj'] ?? '');
    final cepCtrl = TextEditingController(text: cliente?['cep'] ?? '');
    final enderecoCtrl = TextEditingController(text: cliente?['endereco'] ?? '');
    final numeroCtrl = TextEditingController(text: cliente?['numero'] ?? '');
    final cidadeCtrl = TextEditingController(text: cliente?['cidade'] ?? '');
    final estadoCtrl = TextEditingController(text: cliente?['estado'] ?? '');
    final obsCtrl = TextEditingController(text: cliente?['observacoes'] ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdicao ? 'Editar Cliente' : 'Cadastrar Novo Cliente'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nomeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nome Completo / Empresa *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: zapCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefone / WhatsApp',
                  hintText: '(54) 99999-9999',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: cpfCtrl,
                      decoration: const InputDecoration(
                        labelText: 'CPF / CNPJ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: enderecoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Endereço',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: numeroCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nº',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: cidadeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Cidade',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: estadoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'UF',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: cepCtrl,
                      decoration: const InputDecoration(
                        labelText: 'CEP',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: obsCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Observações',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton.icon(
            onPressed: () async {
              if (nomeCtrl.text.trim().isEmpty) return;

              final data = {
                'nome': nomeCtrl.text.trim(),
                'telefoneWhatsapp': zapCtrl.text.trim(),
                'email': emailCtrl.text.trim(),
                'cpfCnpj': cpfCtrl.text.trim(),
                'cep': cepCtrl.text.trim(),
                'endereco': enderecoCtrl.text.trim(),
                'numero': numeroCtrl.text.trim(),
                'cidade': cidadeCtrl.text.trim(),
                'estado': estadoCtrl.text.trim(),
                'observacoes': obsCtrl.text.trim(),
              };

              if (isEdicao) {
                await DbHelper.update('clientes', data, cliente['id']);
              } else {
                await DbHelper.insert('clientes', data);
              }

              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              await _carregarClientes();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isEdicao ? 'Cliente atualizado!' : 'Cliente "${data['nome']}" cadastrado!'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              }
            },
            icon: const Icon(Icons.check),
            label: Text(isEdicao ? 'Salvar' : 'Cadastrar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _excluirCliente(String id, String nome) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Cliente?'),
        content: Text('Deseja remover "$nome" do cadastro?'),
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
      await DbHelper.delete('clientes', id);
      await _carregarClientes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _clientes.where((c) {
      if (_busca.isEmpty) return true;
      final q = _busca.toLowerCase();
      return (c['nome'] ?? '').toString().toLowerCase().contains(q) ||
          (c['telefoneWhatsapp'] ?? '').toString().toLowerCase().contains(q) ||
          (c['email'] ?? '').toString().toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro de Clientes'),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirModalCliente(),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Novo Cliente'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar por nome, WhatsApp ou e-mail...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
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
                              Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              const Text('Nenhum cliente encontrado.'),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filtrados.length,
                          itemBuilder: (context, index) {
                            final c = filtrados[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFFEEF2FF),
                                  child: Text(
                                    (c['nome'] ?? 'C').toString().substring(0, 1).toUpperCase(),
                                    style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(c['nome'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if ((c['telefoneWhatsapp'] ?? '').toString().isNotEmpty)
                                      Text('WhatsApp: ${c['telefoneWhatsapp']}'),
                                    if ((c['cidade'] ?? '').toString().isNotEmpty)
                                      Text('${c['cidade']} - ${c['estado'] ?? ''}'),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.grey),
                                      onPressed: () => _abrirModalCliente(c),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                      onPressed: () => _excluirCliente(c['id'], c['nome'] ?? ''),
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
