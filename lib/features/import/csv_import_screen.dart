import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/expense_repository.dart';
import '../../blocs/expense_bloc.dart';
import '../../blocs/dashboard_bloc.dart';
import '../../blocs/budget_bloc.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';

class CsvImportScreen extends StatefulWidget {
  const CsvImportScreen({super.key});

  @override
  State<CsvImportScreen> createState() => _CsvImportScreenState();
}

class _CsvImportScreenState extends State<CsvImportScreen> {
  final _csvCtl = TextEditingController();
  bool _importing = false;
  String? _resultMessage;

  @override
  void dispose() {
    _csvCtl.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    final raw = _csvCtl.text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppMessages.pasteCsvFirst)),
      );
      return;
    }
    setState(() { _importing = true; _resultMessage = null; });
    try {
      final repo = RepositoryProvider.of<ExpenseRepository>(context);
      final rows = const CsvToListConverter().convert(raw);
      if (rows.isEmpty) throw Exception('Empty CSV');
      final categories = await repo.getCategories(type: 'expense');
      int imported = 0;
      int errors = 0;
      for (int i = 0; i < rows.length; i++) {
        if (i == 0 && rows[i].isNotEmpty) {
          final header = rows[i].map((e) => e.toString().toLowerCase().trim()).toList();
          if (header.contains('date') && header.contains('amount')) continue;
        }
        try {
          final row = rows[i];
          if (row.length < 2) { errors++; continue; }
          final amount = double.tryParse(row[1].toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
          DateTime? date;
          try { date = DateFormat(DateFormats.csv).parse(row[0].toString().trim()); } catch (_) {}
          try { date ??= DateFormat(DateFormats.csvAlt).parse(row[0].toString().trim()); } catch (_) {}
          date ??= DateTime.now();
          String? note;
          if (row.length > 2) note = row[2].toString().trim();
          String? catName;
          if (row.length > 3) catName = row[3].toString().trim();
          int? catId;
          if (catName != null && catName.isNotEmpty) {
            final match = categories.where((c) => c.name.toLowerCase() == catName!.toLowerCase());
            if (match.isNotEmpty) catId = match.first.id;
          }
          await repo.addExpense(
            amount: amount, categoryId: catId ?? categories.first.id, date: date, note: note,
          );
          imported++;
        } catch (_) {
          errors++;
        }
      }
      if (!mounted) return;
      context.read<ExpenseBloc>().add(LoadExpenses());
      context.read<DashboardBloc>().add(LoadDashboard());
      context.read<BudgetBloc>().add(LoadBudgets());
      setState(() {
        _importing = false;
        _resultMessage = 'Imported $imported expenses${errors > 0 ? ' ($errors errors)' : ''}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _importing = false; _resultMessage = ErrorMessages.error(e); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(PageTitles.importCsv)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(UiLabels.pasteCsvHere),
            const SizedBox(height: 8),
            Text('Expected: ${AppMessages.csvHeaders}\nDate: yyyy-MM-dd or MM/dd/yyyy',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _csvCtl,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: UiLabels.csvExample,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_resultMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_resultMessage!, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
              ),
            FilledButton.icon(
              onPressed: _importing ? null : _import,
              icon: _importing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.file_upload),
              label: Text(_importing ? 'Importing...' : 'Import'),
            ),
          ],
        ),
      ),
    );
  }
}
