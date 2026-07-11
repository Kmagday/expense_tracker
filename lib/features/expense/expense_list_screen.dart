import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/expense_bloc.dart';
import '../../blocs/dashboard_bloc.dart';
import '../../blocs/budget_bloc.dart';
import '../../blocs/ai_bloc.dart';
import '../../core/utils/icons_helper.dart';
import 'expense_form_screen.dart';
import '../../blocs/currency_cubit.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  final _searchCtl = TextEditingController();
  final _minAmountCtl = TextEditingController();
  final _maxAmountCtl = TextEditingController();
  final _tagCtl = TextEditingController();
  String _searchText = '';
  int? _filterCategoryId;
  String? _filterPaymentMethod;
  DateTimeRange? _filterDateRange;
  double? _filterMinAmount;
  double? _filterMaxAmount;
  String? _filterTag;

  @override
  void dispose() {
    _searchCtl.dispose();
    _minAmountCtl.dispose();
    _maxAmountCtl.dispose();
    _tagCtl.dispose();
    super.dispose();
  }

  List<dynamic> _applyFilters(List<dynamic> expenses) {
    var filtered = expenses;
    if (_searchText.isNotEmpty) {
      debugPrint('[ExpenseList] filtering by search: $_searchText');
      final q = _searchText.toLowerCase();
      filtered = filtered.where((e) {
        final note = (e.note ?? '').toString().toLowerCase();
        final catName = (e.category?.name ?? '').toString().toLowerCase();
        final tagStr = (e.tags as List?)?.join(' ').toLowerCase() ?? '';
        return note.contains(q) || catName.contains(q) || tagStr.contains(q);
      }).toList();
    }
    if (_filterCategoryId != null) {
      debugPrint('[ExpenseList] filtering by categoryId: $_filterCategoryId');
      filtered = filtered.where((e) => e.categoryId == _filterCategoryId).toList();
    }
    if (_filterPaymentMethod != null) {
      debugPrint('[ExpenseList] filtering by paymentMethod: $_filterPaymentMethod');
      filtered = filtered.where((e) => e.paymentMethod == _filterPaymentMethod).toList();
    }
    if (_filterDateRange != null) {
      debugPrint('[ExpenseList] filtering by dateRange: ${_filterDateRange!.start} - ${_filterDateRange!.end}');
      filtered = filtered.where((e) {
        final d = e.date as DateTime;
        return !d.isBefore(_filterDateRange!.start) && !d.isAfter(_filterDateRange!.end);
      }).toList();
    }
    if (_filterMinAmount != null) {
      filtered = filtered.where((e) => (e.amount as double) >= _filterMinAmount!).toList();
    }
    if (_filterMaxAmount != null) {
      filtered = filtered.where((e) => (e.amount as double) <= _filterMaxAmount!).toList();
    }
    if (_filterTag != null && _filterTag!.isNotEmpty) {
      filtered = filtered.where((e) {
        final tags = e.tags as List? ?? [];
        return tags.any((t) => t.toString().toLowerCase().contains(_filterTag!.toLowerCase()));
      }).toList();
    }
    return filtered;
  }

  void _showFilters(BuildContext context, List<dynamic> categories) {
    _minAmountCtl.text = _filterMinAmount?.toStringAsFixed(2) ?? '';
    _maxAmountCtl.text = _filterMaxAmount?.toStringAsFixed(2) ?? '';
    _tagCtl.text = _filterTag ?? '';
    debugPrint('[ExpenseList] showing filter dialog');
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filters'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int?>(
                  value: _filterCategoryId,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    ...categories.map((c) => DropdownMenuItem(
                      value: c.id,
                      child: Row(children: [
                        Icon(iconFromString(c.icon), size: 18, color: Color(c.color)),
                        const SizedBox(width: 8),
                        Text(c.name),
                      ]),
                    )),
                  ],
                  onChanged: (v) => setDialogState(() => _filterCategoryId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  value: _filterPaymentMethod,
                  decoration: const InputDecoration(labelText: 'Payment Method'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All')),
                    DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'Card', child: Text('Card')),
                    DropdownMenuItem(value: PaymentMethods.eWallet, child: Text(PaymentMethods.eWallet)),
                  ],
                  onChanged: (v) => setDialogState(() => _filterPaymentMethod = v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minAmountCtl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Min \$', border: OutlineInputBorder()),
                        onChanged: (v) => setDialogState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _maxAmountCtl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Max \$', border: OutlineInputBorder()),
                        onChanged: (v) => setDialogState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tagCtl,
                  decoration: const InputDecoration(labelText: 'Tag', hintText: 'Filter by tag', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: Text(_filterDateRange == null
                      ? 'Date Range: All'
                      : '${DateFormat.yMMMd().format(_filterDateRange!.start)} - ${DateFormat.yMMMd().format(_filterDateRange!.end)}'),
                  trailing: const Icon(Icons.edit),
                  onTap: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      initialDateRange: _filterDateRange,
                    );
                    if (picked != null) setDialogState(() => _filterDateRange = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setDialogState(() {
                  _filterCategoryId = null;
                  _filterPaymentMethod = null;
                  _filterDateRange = null;
                  _filterMinAmount = null;
                  _filterMaxAmount = null;
                  _filterTag = null;
                  _minAmountCtl.clear();
                  _maxAmountCtl.clear();
                  _tagCtl.clear();
                });
              },
              child: const Text('Reset'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _filterMinAmount = double.tryParse(_minAmountCtl.text);
                  _filterMaxAmount = double.tryParse(_maxAmountCtl.text);
                  _filterTag = _tagCtl.text.trim();
                  if (_filterTag?.isEmpty == true) _filterTag = null;
                });
                Navigator.pop(ctx);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpenseBloc, ExpenseState>(
      builder: (context, state) {
        final allExpenses = state.expenses;
        final categories = state.categories;
        final currencyFormat = context.watch<CurrencyCubit>().state.formatter;
        final dateFormat = DateFormat(DateFormats.display);

        final expenses = _applyFilters(allExpenses);
        final total = expenses.fold(0.0, (s, e) => s + e.amount);
        final hasFilters = _searchText.isNotEmpty ||
            _filterCategoryId != null ||
            _filterPaymentMethod != null ||
            _filterDateRange != null ||
            _filterMinAmount != null ||
            _filterMaxAmount != null ||
            _filterTag != null;

        return Scaffold(
          appBar: AppBar(title: const Text(PageTitles.allExpenses)),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: TextField(
                  controller: _searchCtl,
                  decoration: InputDecoration(
                    hintText: UiLabels.searchHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchText.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtl.clear();
                              setState(() => _searchText = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (v) => setState(() => _searchText = v),
                ),
              ),
              Row(
                children: [
                  const SizedBox(width: 16),
                  Text('${expenses.length} expenses',
                      style: Theme.of(context).textTheme.titleSmall),
                  const Spacer(),
                  TextButton.icon(
                    icon: Icon(hasFilters ? Icons.filter_alt : Icons.filter_alt_outlined),
                    label: Text(hasFilters ? 'Filters On' : 'Filters'),
                    onPressed: () => _showFilters(context, categories),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
              if (hasFilters)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 6,
                    children: [
                      if (_filterCategoryId != null)
                        Chip(
                          label: Text('Category: ${categories.firstWhere((c) => c.id == _filterCategoryId).name}'),
                          onDeleted: () => setState(() => _filterCategoryId = null),
                        ),
                      if (_filterPaymentMethod != null)
                        Chip(
                          label: Text('Payment: $_filterPaymentMethod'),
                          onDeleted: () => setState(() => _filterPaymentMethod = null),
                        ),
                      if (_filterDateRange != null)
                        Chip(
                          label: Text('${DateFormat.MMMd().format(_filterDateRange!.start)}-${DateFormat.MMMd().format(_filterDateRange!.end)}'),
                          onDeleted: () => setState(() => _filterDateRange = null),
                        ),
                      if (_filterMinAmount != null)
                        Chip(
                          label: Text('Min: \$${_filterMinAmount!.toStringAsFixed(0)}'),
                          onDeleted: () => setState(() => _filterMinAmount = null),
                        ),
                      if (_filterMaxAmount != null)
                        Chip(
                          label: Text('Max: \$${_filterMaxAmount!.toStringAsFixed(0)}'),
                          onDeleted: () => setState(() => _filterMaxAmount = null),
                        ),
                      if (_filterTag != null)
                        Chip(
                          label: Text('Tag: $_filterTag'),
                          onDeleted: () => setState(() => _filterTag = null),
                        ),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                alignment: Alignment.centerRight,
                child: Text('Total: ${currencyFormat.format(total)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: expenses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(allExpenses.isEmpty ? Icons.receipt_long_outlined : Icons.search_off,
                                size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              allExpenses.isEmpty
                                  ? 'No expenses yet. Tap + to add one!'
                                  : 'No expenses match your filters.',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          context.read<ExpenseBloc>().add(LoadExpenses());
                          context.read<DashboardBloc>().add(LoadDashboard());
                          context.read<BudgetBloc>().add(LoadBudgets());
                          context.read<AIBloc>().add(LoadAIInsights());
                        },
                        child: ListView.builder(
                          itemCount: expenses.length,
                          itemBuilder: (ctx, i) {
                            final e = expenses[i];
                            return Dismissible(
                              key: ValueKey(e.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 16),
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              confirmDismiss: (_) => showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text(UiLabels.deleteExpenseTitle),
                                  content: Text('Delete ${currencyFormat.format(e.amount)} expense? It will be moved to trash.'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                  ],
                                ),
                              ),
                              onDismissed: (_) {
                                context.read<ExpenseBloc>().add(DeleteExpenseEvent(e.id));
                                context.read<DashboardBloc>().add(LoadDashboard());
                                context.read<BudgetBloc>().add(LoadBudgets());
                                context.read<AIBloc>().add(LoadAIInsights());
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(AppMessages.expenseDeleted),
                                    action: SnackBarAction(label: 'Undo', onPressed: () {
                                      context.read<ExpenseBloc>().add(LoadExpenses());
                                    }),
                                  ),
                                );
                              },
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Color(e.category?.color ?? 0xFF757575).withValues(alpha: 0.2),
                                child: Icon(
                                  iconFromString(e.category?.icon ?? 'receipt'),
                                  color: Color(e.category?.color ?? 0xFF757575), size: 20,
                                ),
                              ),
                              title: Text(e.category?.name ?? 'Other'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(dateFormat.format(e.date)),
                                      if (e.receiptPath != null) ...[
                                        const SizedBox(width: 6),
                                        const Icon(Icons.receipt_long, size: 14, color: Colors.grey),
                                      ],
                                    ],
                                  ),
                                  if ((e.tags as List?)?.isNotEmpty == true)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Wrap(
                                        spacing: 4,
                                        runSpacing: 2,
                                        children: (e.tags as List).take(3).map<Widget>((tag) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.secondaryContainer,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(tag.toString(), style: const TextStyle(fontSize: 10)),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Text(
                                currencyFormat.format(e.amount),
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                              ),
                              onTap: () => _openEdit(context, e),
                            ),
                          );
                        },
                      ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openEdit(BuildContext context, dynamic e) async {
    debugPrint('[ExpenseList] opening edit for expense id=${e.id}');
    final changed = await Navigator.push<bool>(context, MaterialPageRoute(
      builder: (_) => ExpenseFormScreen(expense: e),
    ));
    debugPrint('[ExpenseList] edit returned changed=$changed');
    if (changed == true && context.mounted) {
      context.read<ExpenseBloc>().add(LoadExpenses());
      context.read<DashboardBloc>().add(LoadDashboard());
      context.read<BudgetBloc>().add(LoadBudgets());
      context.read<AIBloc>().add(LoadAIInsights());
    }
  }
}
