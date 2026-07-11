import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../data/repositories/expense_repository.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';

class PdfReportScreen extends StatefulWidget {
  const PdfReportScreen({super.key});

  @override
  State<PdfReportScreen> createState() => _PdfReportScreenState();
}

class _PdfReportScreenState extends State<PdfReportScreen> {
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text(PageTitles.pdfReport)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.picture_as_pdf, size: 80, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Generate a PDF report of all your expenses,\nincomes, and budgets for the current month.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _generatePdfReport,
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.file_present),
                  label: Text(_isGenerating ? 'Generating…' : UiLabels.generatePdf),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generatePdfReport() async {
    setState(() => _isGenerating = true);
    try {
      final repo = RepositoryProvider.of<ExpenseRepository>(context);
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final expenses = await repo.getExpenses(from: startOfMonth, to: endOfMonth);
      final incomes = await repo.getIncomes(from: startOfMonth, to: endOfMonth);
      final budgets = await repo.getBudgets(now.month, now.year);

      final totalExpenses = expenses.fold(0.0, (s, e) => s + e.amount);
      final totalIncome = incomes.fold(0.0, (s, i) => s + i.amount);
      final netBalance = totalIncome - totalExpenses;

      final monthYear = DateFormat(DateFormats.reportMonth).format(now);
      final dateStr = DateFormat(DateFormats.fileTimestamp).format(now);

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(AppFiles.pdfShareText, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Paragraph(text: 'Period: $monthYear'),
              pw.SizedBox(height: 12),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _summaryBox('Total Expenses', '\$${totalExpenses.toStringAsFixed(2)}', PdfColors.red),
                  _summaryBox('Total Income', '\$${totalIncome.toStringAsFixed(2)}', PdfColors.green),
                  _summaryBox(
                    UiLabels.netBalance,
                    '\$${netBalance.toStringAsFixed(2)}',
                    netBalance >= 0 ? PdfColors.green : PdfColors.red,
                  ),
                ],
              ),
              pw.SizedBox(height: 24),
              if (expenses.isNotEmpty) ...[
                pw.Header(level: 1, child: pw.Text('Expenses')),
                pw.TableHelper.fromTextArray(
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                  cellStyle: pw.TextStyle(fontSize: 9),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.centerRight,
                    2: pw.Alignment.centerLeft,
                    3: pw.Alignment.centerLeft,
                  },
                  headers: [UiLabels.date, UiLabels.amount, UiLabels.category, 'Note'],
                  data: expenses.map((e) => [
                    DateFormat(DateFormats.csv).format(e.date),
                    '\$${e.amount.toStringAsFixed(2)}',
                    e.category?.name ?? 'Other',
                    e.note ?? '',
                  ]).toList(),
                ),
              ],
              if (incomes.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                pw.Header(level: 1, child: pw.Text('Income')),
                pw.TableHelper.fromTextArray(
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                  cellStyle: pw.TextStyle(fontSize: 9),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.centerRight,
                    2: pw.Alignment.centerLeft,
                    3: pw.Alignment.centerLeft,
                  },
                  headers: [UiLabels.date, UiLabels.amount, 'Source', 'Note'],
                  data: incomes.map((i) => [
                    DateFormat(DateFormats.csv).format(i.date),
                    '\$${i.amount.toStringAsFixed(2)}',
                    i.source ?? i.category?.name ?? 'Other',
                    i.note ?? '',
                  ]).toList(),
                ),
              ],
              if (budgets.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                pw.Header(level: 1, child: pw.Text('Budgets')),
                pw.TableHelper.fromTextArray(
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                  cellStyle: pw.TextStyle(fontSize: 9),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.centerRight,
                    2: pw.Alignment.centerRight,
                    3: pw.Alignment.centerRight,
                  },
                  headers: [UiLabels.category, 'Budget', 'Spent', 'Remaining'],
                  data: budgets.map((b) => [
                    b.category?.name ?? 'Overall',
                    '\$${b.budgetAmount.toStringAsFixed(2)}',
                    '\$${b.spentAmount.toStringAsFixed(2)}',
                    '\$${b.remaining.toStringAsFixed(2)}',
                  ]).toList(),
                ),
              ],
              if (expenses.isEmpty && incomes.isEmpty && budgets.isEmpty)
                pw.Paragraph(text: 'No data found for this period.'),
            ];
          },
        ),
      );

      final Uint8List bytes = await pdf.save();
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${AppFiles.pdfPrefix}$dateStr.pdf');
      await file.writeAsBytes(bytes);

      debugPrint('[PdfReport] Report saved to ${file.path}');

      if (mounted) {
        await Share.shareXFiles([XFile(file.path)], text: AppFiles.pdfShareText);
      }
    } catch (e) {
      debugPrint('[PdfReport] Error generating report: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorMessages.pdfError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  pw.Widget _summaryBox(String label, String value, PdfColor color) {
    return pw.Container(
      width: 140,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: color, width: 2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
