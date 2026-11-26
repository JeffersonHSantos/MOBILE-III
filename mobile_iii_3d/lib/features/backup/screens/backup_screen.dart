import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../database/db_helper.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final _importJsonController = TextEditingController();
  bool _isExporting = false;
  bool _isImporting = false;
  String? _exportedJsonPreview;

  Future<void> _exportarDados() async {
    setState(() => _isExporting = true);
    try {
      final jsonStr = await DbHelper.exportarBancoJson();
      setState(() {
        _exportedJsonPreview = jsonStr;
        _isExporting = false;
      });

      await Clipboard.setData(ClipboardData(text: jsonStr));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup JSON gerado e copiado para a Área de Transferência!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      setState(() => _isExporting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao exportar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _importarDados() async {
    final text = _importJsonController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cole o JSON de backup para importar.')),
      );
      return;
    }

    setState(() => _isImporting = true);
    try {
      await DbHelper.importarBancoJson(text);
      setState(() {
        _isImporting = false;
        _importJsonController.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Banco de dados e estoque sincronizados com sucesso!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      setState(() => _isImporting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao importar JSON: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Sincronização'),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card Firebase Free Cloud
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFC7D2FE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_done_rounded, color: Color(0xFF4F46E5), size: 36),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Sincronização em Nuvem Firebase (Plano Free)',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B)),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Seu projeto está conectado ao Firebase Auth e pronto para persistência no Cloud Firestore.',
                          style: TextStyle(color: Color(0xFF4B5563), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Seção Exportar
            const Text(
              '1. Exportar Estoque e Banco Local (JSON)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Exporte todo o estoque de filamentos, insumos, orçamentos e histórico para compartilhar com outras pessoas ou fazer backup preventivo.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isExporting ? null : _exportarDados,
              icon: const Icon(Icons.file_download_outlined),
              label: Text(_isExporting ? 'Exportando...' : 'Exportar & Copiar Backup JSON'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            if (_exportedJsonPreview != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _exportedJsonPreview!,
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontFamily: 'monospace'),
                  ),
                ),
              ),
            ],

            const Divider(height: 40),

            // Seção Importar
            const Text(
              '2. Importar / Restaurar Estoque de Outro Usuário',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cole o JSON de estoque ou backup recebido para atualizar as quantidades e dados em tempo real no seu dispositivo.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _importJsonController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Cole o código JSON aqui...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isImporting ? null : _importarDados,
              icon: const Icon(Icons.upload_file_rounded),
              label: Text(_isImporting ? 'Importando...' : 'Importar e Mesclar Dados'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
