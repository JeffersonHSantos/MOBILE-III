import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';

class ParsedFilamentSlot {
  final int slotIndex;
  final String material;
  final String colorHex;
  final double weightGrams;

  ParsedFilamentSlot({
    required this.slotIndex,
    required this.material,
    required this.colorHex,
    required this.weightGrams,
  });

  Map<String, dynamic> toMap() {
    return {
      'slotIndex': slotIndex,
      'material': material,
      'colorHex': colorHex,
      'weightGrams': weightGrams,
    };
  }
}

class SlicerParseResult {
  final String fileName;
  final int totalTimeMinutes;
  final double totalWeightGrams;
  final double purgeWeightGrams;
  final int filamentChanges;
  final List<ParsedFilamentSlot> filaments;
  final Uint8List? thumbnailBytes;

  SlicerParseResult({
    required this.fileName,
    required this.totalTimeMinutes,
    required this.totalWeightGrams,
    required this.purgeWeightGrams,
    required this.filamentChanges,
    required this.filaments,
    this.thumbnailBytes,
  });
}

class SlicerParserService {
  /// Faz o parse nativo de arquivos .3mf (Bambu Studio, OrcaSlicer, PrusaSlicer)
  static SlicerParseResult parse3mfBytes(Uint8List bytes, String fileName) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);

      int totalTimeMinutes = 0;
      double totalWeightGrams = 0.0;
      double purgeWeightGrams = 0.0;
      int filamentChanges = 0;
      final List<ParsedFilamentSlot> filaments = [];
      Uint8List? thumbnailBytes;

      // 1. Procurar miniaturas (Thumbnails)
      for (final file in archive.files) {
        final lowerName = file.name.toLowerCase();
        if (lowerName.endsWith('thumbnail.png') ||
            lowerName.contains('plate_') && lowerName.endsWith('.png')) {
          thumbnailBytes = file.content;
          break;
        }
      }

      // 2. Procurar slice_info.config (Bambu Studio / OrcaSlicer)
      ArchiveFile? sliceInfoFile;
      for (final file in archive.files) {
        if (file.name.endsWith('slice_info.config')) {
          sliceInfoFile = file;
          break;
        }
      }

      if (sliceInfoFile != null) {
        final content = utf8.decode(sliceInfoFile.content as List<int>, allowMalformed: true);
        final parsedXml = _parseXmlOrConfig(content);

        totalTimeMinutes = parsedXml['timeMinutes'] ?? 0;
        totalWeightGrams = parsedXml['totalWeightGrams'] ?? 0.0;
        purgeWeightGrams = parsedXml['purgeWeightGrams'] ?? 0.0;
        filamentChanges = parsedXml['filamentChanges'] ?? 0;

        final rawFilaments = parsedXml['filaments'] as List<ParsedFilamentSlot>? ?? [];
        filaments.addAll(rawFilaments);
      }

      // Se não encontrou dados estruturados no XML, busca em arquivos de configuração alternativos
      if (filaments.isEmpty) {
        for (final file in archive.files) {
          if (file.name.endsWith('.gcode') || file.name.endsWith('gcode.txt')) {
            final content = utf8.decode(file.content as List<int>, allowMalformed: true);
            final gcodeResult = parseGcodeString(content, fileName);
            if (gcodeResult.totalTimeMinutes > 0 || gcodeResult.totalWeightGrams > 0) {
              return SlicerParseResult(
                fileName: fileName,
                totalTimeMinutes: gcodeResult.totalTimeMinutes,
                totalWeightGrams: gcodeResult.totalWeightGrams,
                purgeWeightGrams: gcodeResult.purgeWeightGrams,
                filamentChanges: gcodeResult.filamentChanges,
                filaments: gcodeResult.filaments,
                thumbnailBytes: thumbnailBytes ?? gcodeResult.thumbnailBytes,
              );
            }
          }
        }
      }

      // Se ainda estiver zerado, cria pelo menos um slot padrão com o peso total
      if (filaments.isEmpty && totalWeightGrams > 0) {
        filaments.add(ParsedFilamentSlot(
          slotIndex: 1,
          material: 'PLA',
          colorHex: '#111827',
          weightGrams: totalWeightGrams,
        ));
      }

      return SlicerParseResult(
        fileName: fileName,
        totalTimeMinutes: totalTimeMinutes,
        totalWeightGrams: totalWeightGrams,
        purgeWeightGrams: purgeWeightGrams,
        filamentChanges: filamentChanges,
        filaments: filaments,
        thumbnailBytes: thumbnailBytes,
      );
    } catch (e) {
      debugPrint('Erro ao fazer parse do .3mf: $e');
      return SlicerParseResult(
        fileName: fileName,
        totalTimeMinutes: 0,
        totalWeightGrams: 0,
        purgeWeightGrams: 0,
        filamentChanges: 0,
        filaments: [],
      );
    }
  }

  /// Faz o parse de arquivo GCODE por Regex
  static SlicerParseResult parseGcodeString(String content, String fileName) {
    int totalTimeMinutes = 0;
    double totalWeightGrams = 0.0;
    double purgeWeightGrams = 0.0;
    int filamentChanges = 0;
    final List<ParsedFilamentSlot> filaments = [];

    // Regex para tempo de impressão
    // Ex: "; estimated printing time (normal mode) = 1h 45m 12s" ou "; TIME:6312"
    final timeSecMatch = RegExp(r';\s*TIME:(\d+)').firstMatch(content);
    if (timeSecMatch != null) {
      final seconds = int.tryParse(timeSecMatch.group(1) ?? '0') ?? 0;
      totalTimeMinutes = (seconds / 60).round();
    } else {
      final timeTextMatch = RegExp(r';\s*estimated printing time.*?=\s*(.*)', caseSensitive: false).firstMatch(content);
      if (timeTextMatch != null) {
        final timeStr = timeTextMatch.group(1) ?? '';
        totalTimeMinutes = _parseDurationStringToMinutes(timeStr);
      }
    }

    // Regex para peso do filamento
    // Ex: "; total filament used [g] = 48.5" ou "; filament used [g] = 48.5"
    final weightMatches = RegExp(r';\s*filament used\s*\[g\]\s*=\s*([\d\.,\s]+)', caseSensitive: false).allMatches(content);
    final List<double> weightsFound = [];
    for (final match in weightMatches) {
      final parts = match.group(1)?.split(',') ?? [];
      for (final p in parts) {
        final val = double.tryParse(p.trim());
        if (val != null && val > 0) weightsFound.add(val);
      }
    }

    if (weightsFound.isNotEmpty) {
      totalWeightGrams = weightsFound.reduce((a, b) => a + b);
      int slot = 1;
      for (final w in weightsFound) {
        filaments.add(ParsedFilamentSlot(
          slotIndex: slot,
          material: 'PLA',
          colorHex: slot == 1 ? '#111827' : '#EF4444',
          weightGrams: w,
        ));
        slot++;
      }
    }

    // Contagem de trocas de filamento (M600 ou T0, T1...)
    final toolChangeMatches = RegExp(r'^\s*T[0-9]+\b', multiLine: true).allMatches(content);
    if (toolChangeMatches.length > 1) {
      filamentChanges = toolChangeMatches.length - 1;
    }

    return SlicerParseResult(
      fileName: fileName,
      totalTimeMinutes: totalTimeMinutes,
      totalWeightGrams: totalWeightGrams,
      purgeWeightGrams: purgeWeightGrams,
      filamentChanges: filamentChanges,
      filaments: filaments,
    );
  }

  // ==========================================
  // AUXILIARES DE PARSE
  // ==========================================
  static Map<String, dynamic> _parseXmlOrConfig(String xmlText) {
    int timeMinutes = 0;
    double totalWeightGrams = 0.0;
    double purgeWeightGrams = 0.0;
    int filamentChanges = 0;
    final List<ParsedFilamentSlot> filaments = [];

    try {
      final document = XmlDocument.parse(xmlText);
      final plateElements = document.findAllElements('plate');

      for (final plate in plateElements) {
        // Tempo previsto
        final prediction = plate.findElements('prediction').firstOrNull?.innerText;
        if (prediction != null) {
          final seconds = int.tryParse(prediction) ?? 0;
          timeMinutes += (seconds / 60).round();
        }

        // Filamentos usados
        final filamentElements = plate.findAllElements('filament');
        int slot = 1;
        for (final fil in filamentElements) {
          final usedGrams = double.tryParse(fil.getAttribute('used_g') ?? '0') ?? 0.0;
          final type = fil.getAttribute('type') ?? 'PLA';
          final color = fil.getAttribute('color') ?? '#111827';

          if (usedGrams > 0) {
            totalWeightGrams += usedGrams;
            filaments.add(ParsedFilamentSlot(
              slotIndex: slot,
              material: type,
              colorHex: color.startsWith('#') ? color : '#$color',
              weightGrams: usedGrams,
            ));
          }
          slot++;
        }

        // Purga / Flush
        final purgeG = double.tryParse(plate.findElements('flush_weight').firstOrNull?.innerText ?? '0') ?? 0.0;
        purgeWeightGrams += purgeG;

        // Trocas
        final changes = int.tryParse(plate.findElements('filament_change').firstOrNull?.innerText ?? '0') ?? 0;
        filamentChanges += changes;
      }
    } catch (_) {
      // Fallback para busca por regex em caso de XML truncado
      final timeMatch = RegExp(r'<prediction>(\d+)</prediction>').firstMatch(xmlText);
      if (timeMatch != null) {
        final sec = int.tryParse(timeMatch.group(1) ?? '0') ?? 0;
        timeMinutes = (sec / 60).round();
      }

      final usedMatch = RegExp(r'used_g="([\d\.]+)"').allMatches(xmlText);
      int slot = 1;
      for (final m in usedMatch) {
        final g = double.tryParse(m.group(1) ?? '0') ?? 0.0;
        if (g > 0) {
          totalWeightGrams += g;
          filaments.add(ParsedFilamentSlot(
            slotIndex: slot++,
            material: 'PLA',
            colorHex: '#111827',
            weightGrams: g,
          ));
        }
      }
    }

    return {
      'timeMinutes': timeMinutes,
      'totalWeightGrams': totalWeightGrams,
      'purgeWeightGrams': purgeWeightGrams,
      'filamentChanges': filamentChanges,
      'filaments': filaments,
    };
  }

  static int _parseDurationStringToMinutes(String timeStr) {
    int total = 0;
    final hoursMatch = RegExp(r'(\d+)\s*h').firstMatch(timeStr);
    final minsMatch = RegExp(r'(\d+)\s*m').firstMatch(timeStr);
    if (hoursMatch != null) {
      total += (int.tryParse(hoursMatch.group(1) ?? '0') ?? 0) * 60;
    }
    if (minsMatch != null) {
      total += int.tryParse(minsMatch.group(1) ?? '0') ?? 0;
    }
    return total;
  }
}
