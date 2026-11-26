import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

Future<String?> showBarcodeScannerModal(BuildContext context) async {
  return showDialog<String>(
    context: context,
    builder: (ctx) {
      bool detected = false;
      final manualCtrl = TextEditingController();

      return AlertDialog(
        title: const Text('Leitor de Código de Barras / QR'),
        content: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 220,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: MobileScanner(
                    onDetect: (capture) {
                      if (detected) return;
                      final barcodes = capture.barcodes;
                      if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                        detected = true;
                        Navigator.pop(ctx, barcodes.first.rawValue);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: manualCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ou digite o código manualmente',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (val) => Navigator.pop(ctx, val.trim()),
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
            onPressed: () => Navigator.pop(ctx, manualCtrl.text.trim()),
            child: const Text('Confirmar Código'),
          ),
        ],
      );
    },
  );
}
