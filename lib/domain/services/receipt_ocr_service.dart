import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ReceiptData {
  final double? amount;
  final DateTime? date;
  final String? merchant;
  final String rawText;

  const ReceiptData({this.amount, this.date, this.merchant, required this.rawText});
}

class ReceiptOcrService {
  final _recognizer = TextRecognizer();

  void dispose() => _recognizer.close();

  Future<ReceiptData> processImage(String imagePath) async {
    debugPrint('[ReceiptOCR] processing image: $imagePath');
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizedText = await _recognizer.processImage(inputImage);
    final text = recognizedText.text;
    debugPrint('[ReceiptOCR] raw text length: ${text.length} chars, lines: ${text.split('\n').length}');

    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    final amount = _extractAmount(lines);
    final date = _extractDate(text);
    final merchant = _extractMerchant(lines);
    debugPrint('[ReceiptOCR] extracted - amount: $amount, date: $date, merchant: $merchant');

    return ReceiptData(
      amount: amount,
      date: date,
      merchant: merchant,
      rawText: text,
    );
  }

  double? _extractAmount(List<String> lines) {
    final amountPattern = RegExp(
      r'(?:total|amount due|amount|balance due|grand total|due|paid|charge)\s*:?\s*\$?\s*([0-9]+\.?[0-9]{0,2})',
      caseSensitive: false,
    );
    final simplePattern = RegExp(r'^\$?\s*([0-9]+\.\d{2})\s*$');

    double? bestAmount;
    int bestScore = -1;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toLowerCase();

      // Check for labeled total first (higher confidence)
      final match = amountPattern.firstMatch(line);
      if (match != null) {
        final value = double.tryParse(match.group(1)!);
        if (value != null && value > 0 && (bestAmount == null || value > bestAmount)) {
          // Prefer larger amounts (total is usually the largest number on a receipt)
          if (value > (bestAmount ?? 0)) {
            bestAmount = value;
            bestScore = 10;
          }
        }
      }

      // Check for standalone amounts (lower confidence)
      final simple = simplePattern.firstMatch(lines[i]);
      if (simple != null) {
        final value = double.tryParse(simple.group(1)!);
        if (value != null && value > 0) {
          if (value > (bestAmount ?? 0) && bestScore < 5) {
            bestAmount = value;
            bestScore = 5;
          }
        }
      }
    }

    return bestAmount;
  }

  DateTime? _extractDate(String text) {
    // Try multiple date formats
    final patterns = [
      RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})'),   // MM/DD/YYYY or MM-DD-YYYY
      RegExp(r'(\d{4})[/-](\d{1,2})[/-](\d{1,2})'),       // YYYY-MM-DD
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        try {
          final parts = match.groups([1, 2, 3]).map((e) => int.tryParse(e ?? '')).toList();
          if (parts.any((p) => p == null)) continue;

          if (pattern == patterns[0]) {
            // MM/DD/YYYY or DD/MM/YYYY
            final m = parts[0]!;
            final d = parts[1]!;
            var y = parts[2]!;
            if (y < 100) y += 2000;
            if (m >= 1 && m <= 12 && d >= 1 && d <= 31) {
              return DateTime(y, m, d);
            }
          } else {
            // YYYY-MM-DD
            return DateTime(parts[0]!, parts[1]!, parts[2]!);
          }
        } catch (_) {}
      }
    }
    return null;
  }

  String? _extractMerchant(List<String> lines) {
    if (lines.isEmpty) return null;

    // First non-empty line that isn't a phone number, address, or date
    for (final line in lines.take(5)) {
      final lower = line.toLowerCase();
      if (lower.contains('receipt') || lower.contains('invoice') ||
          lower.contains('thank you') || lower.contains('store') ||
          lower.contains('#') || lower.contains('www.') ||
          lower.contains('@') || lower.contains('phone') ||
          lower.contains('tel:') || RegExp(r'^\d+$').hasMatch(line) ||
          RegExp(r'^\d{3}[-.]?\d{3}[-.]?\d{4}$').hasMatch(line)) {
        continue;
      }
      if (line.length >= 3 && line.length <= 50) {
        return line;
      }
    }
    return null;
  }
}
