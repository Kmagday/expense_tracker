import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/models/expense_models.dart';
import '../../core/utils/icons_helper.dart';
import '../../blocs/expense_bloc.dart';
import '../../blocs/income_bloc.dart';
import '../../blocs/budget_bloc.dart';
import '../../blocs/dashboard_bloc.dart';
import '../../blocs/ai_bloc.dart';
import '../../blocs/currency_cubit.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ExpenseModel> _expenses = [];
  List<IncomeModel> _incomes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDeleted();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDeleted() async {
    setState(() => _loading = true);
    try {
      final repo = RepositoryProvider.of<ExpenseRepository>(context);
      final exps = await repo.getDeletedExpenses();
      final incs = await repo.getDeletedIncomes();
      if (!mounted) return;
      setState(() {
        _expenses = exps;
        _incomes = incs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load deleted items: $e')),
      );
    }
  }

  void _refreshBlocs() {
    context.read<ExpenseBloc>().add(LoadExpenses());
    context.read<IncomeBloc>().add(LoadIncomes());
    context.read<BudgetBloc>().add(LoadBudgets());
    context.read<DashboardBloc>().add(LoadDashboard());
    context.read<AIBloc>().add(LoadAIInsights());
  }

  Future<void> _restoreExpense(ExpenseModel e) async {
    final repo = RepositoryProvider.of<ExpenseRepository>(context);
    await repo.restoreExpense(e.id);
    _refreshBlocs();
    _loadDeleted();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Expense restored — ${context.read<CurrencyCubit>().state.symbol}${e.amount.toStringAsFixed(2)}')),
      );
    }
  }

  Future<void> _restoreIncome(IncomeModel i) async {
    final repo = RepositoryProvider.of<ExpenseRepository>(context);
    await repo.restoreIncome(i.id);
    _refreshBlocs();
    _loadDeleted();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Income restored — ${context.read<CurrencyCubit>().state.symbol}${i.amount.toStringAsFixed(2)}')),
      );
    }
  }

  Future<bool> _confirmDelete(BuildContext ctx, String itemLabel) async {
    return await showDialog<bool>(
      context: ctx,
      builder: (d) => AlertDialog(
        title: const Text(UiLabels.permanentlyDelete),
        content: Text('Delete "$itemLabel" forever? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Delete Forever', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _hardDeleteExpense(ExpenseModel e) async {
    final confirmed = await _confirmDelete(context, '${e.category?.name ?? 'Expense'} — ${context.read<CurrencyCubit>().state.symbol}${e.amount.toStringAsFixed(2)}');
    if (!confirmed || !mounted) return;
    final repo = RepositoryProvider.of<ExpenseRepository>(context);
    await repo.hardDeleteExpense(e.id);
    _refreshBlocs();
    _loadDeleted();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppMessages.expensePermDeleted)),
      );
    }
  }

  Future<void> _hardDeleteIncome(IncomeModel i) async {
    final confirmed = await _confirmDelete(context, '${i.category?.name ?? 'Income'} — ${context.read<CurrencyCubit>().state.symbol}${i.amount.toStringAsFixed(2)}');
    if (!confirmed || !mounted) return;
    final repo = RepositoryProvider.of<ExpenseRepository>(context);
    await repo.hardDeleteIncome(i.id);
    _refreshBlocs();
    _loadDeleted();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppMessages.incomePermDeleted)),
      );
    }
  }

  Future<void> _purgeAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text(UiLabels.emptyTrashTitle),
        content: const Text('Permanently delete all items in the trash? Items deleted over 30 days ago will be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(d, true),
              child: const Text(UiLabels.emptyTrash, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final repo = RepositoryProvider.of<ExpenseRepository>(context);
    final count = await repo.purgeOldDeleted();
    _refreshBlocs();
    _loadDeleted();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Trash emptied — $count items removed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = context.watch<CurrencyCubit>().state.formatter;
    final dateFormat = DateFormat(DateFormats.display);
    final totalTrash = _expenses.length + _incomes.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash'),
        actions: [
          if (totalTrash > 0)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: UiLabels.emptyTrash,
              onPressed: _purgeAll,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Expenses (${_expenses.length})'),
            Tab(text: 'Incomes (${_incomes.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : totalTrash == 0
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('Trash is empty', style: theme.textTheme.titleLarge?.copyWith(color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      Text('Deleted items appear here for 30 days', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[500])),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildExpenseList(theme, currencyFormat, dateFormat),
                    _buildIncomeList(theme, currencyFormat, dateFormat),
                  ],
                ),
    );
  }

  Widget _buildExpenseList(ThemeData theme, NumberFormat currencyFormat, DateFormat dateFormat) {
    if (_expenses.isEmpty) {
      return Center(
        child: Text('No deleted expenses', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
      );
    }
    return ListView.builder(
      itemCount: _expenses.length,
      itemBuilder: (context, index) {
        final e = _expenses[index];
        final cat = e.category;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(cat?.color ?? 0xFF757575).withValues(alpha: 0.2),
              child: Icon(iconFromString(cat?.icon ?? 'receipt'),
                  color: Color(cat?.color ?? 0xFF757575), size: 20),
            ),
            title: Text(cat?.name ?? 'Deleted Category', style: theme.textTheme.bodyMedium),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${dateFormat.format(e.date)} • ${context.read<CurrencyCubit>().state.symbol}${e.amount.toStringAsFixed(2)}'),
                Text('Deleted ${dateFormat.format(e.createdAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500])),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.restore_from_trash, color: Colors.green[700]),
                  tooltip: UiLabels.restore,
                  onPressed: () => _restoreExpense(e),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  tooltip: 'Delete forever',
                  onPressed: () => _hardDeleteExpense(e),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIncomeList(ThemeData theme, NumberFormat currencyFormat, DateFormat dateFormat) {
    if (_incomes.isEmpty) {
      return Center(
        child: Text('No deleted incomes', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
      );
    }
    return ListView.builder(
      itemCount: _incomes.length,
      itemBuilder: (context, index) {
        final i = _incomes[index];
        final cat = i.category;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(cat?.color ?? 0xFF757575).withValues(alpha: 0.2),
              child: Icon(iconFromString(cat?.icon ?? 'trending_up'),
                  color: Color(cat?.color ?? 0xFF757575), size: 20),
            ),
            title: Text(cat?.name ?? 'Deleted Category', style: theme.textTheme.bodyMedium),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${dateFormat.format(i.date)} • ${context.read<CurrencyCubit>().state.symbol}${i.amount.toStringAsFixed(2)}'),
                Text('Deleted ${dateFormat.format(i.createdAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500])),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.restore_from_trash, color: Colors.green[700]),
                  tooltip: UiLabels.restore,
                  onPressed: () => _restoreIncome(i),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  tooltip: 'Delete forever',
                  onPressed: () => _hardDeleteIncome(i),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
