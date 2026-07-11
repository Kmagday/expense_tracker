import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/database/app_database.dart';
import '../../services/backup_service.dart';
import '../../blocs/expense_bloc.dart';
import '../../blocs/income_bloc.dart';
import '../../blocs/dashboard_bloc.dart';
import '../../blocs/budget_bloc.dart';
import '../../blocs/ai_bloc.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final _passCtl = TextEditingController();
  final _importCtl = TextEditingController();
  bool _busy = false;
  String? _result;

  @override
  void dispose() {
    _passCtl.dispose();
    _importCtl.dispose();
    super.dispose();
  }

  Future<void> _export() async {
    final pass = _passCtl.text.trim();
    if (pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppMessages.enterPassphrase)),
      );
      return;
    }
    if (pass.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppMessages.passphraseTooShort)),
      );
      return;
    }
    setState(() { _busy = true; _result = null; });
    try {
      final db = RepositoryProvider.of<AppDatabase>(context);
      final service = BackupService(db);
      await service.exportToFile(pass);
      setState(() => _result = AppMessages.backupExported);
    } catch (e) {
      setState(() => _result = ErrorMessages.exportError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final pass = _passCtl.text.trim();
    final data = _importCtl.text.trim();
    if (pass.isEmpty || data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppMessages.enterPassphraseAndData)),
      );
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(UiLabels.importBackup),
        content: const Text(UiLabels.restoreWarning),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Import', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() { _busy = true; _result = null; });
    try {
      final db = RepositoryProvider.of<AppDatabase>(context);
      final service = BackupService(db);
      final count = await service.importBackup(data, pass);
      if (mounted) {
        context.read<ExpenseBloc>().add(LoadExpenses());
        context.read<IncomeBloc>().add(LoadIncomes());
        context.read<DashboardBloc>().add(LoadDashboard());
        context.read<BudgetBloc>().add(LoadBudgets());
        context.read<AIBloc>().add(LoadAIInsights());
        setState(() => _result = ErrorMessages.importedCount(count));
      }
    } catch (e) {
      setState(() => _result = ErrorMessages.importError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(PageTitles.backup)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Icon(Icons.lock_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 8),
          const Text(
            UiLabels.backupPrivacy,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _passCtl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: UiLabels.passphrase,
              hintText: UiLabels.passphraseHint,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _export,
            icon: _busy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.file_upload),
            label: const Text(UiLabels.exportBackup),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          const Text(UiLabels.restoreFromBackup, style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _importCtl,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: UiLabels.pasteBackupHere,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _busy ? null : _import,
            icon: _busy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.file_download),
            label: const Text(UiLabels.restoreBackup),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          ),
          if (_result != null) ...[
            const SizedBox(height: 16),
            Text(_result!, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}
