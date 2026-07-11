import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../data/models/expense_models.dart';
import '../../blocs/income_bloc.dart';
import '../../blocs/dashboard_bloc.dart';
import '../../core/utils/icons_helper.dart';
import 'income_form_screen.dart';
import '../../blocs/currency_cubit.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';

class IncomeListScreen extends StatefulWidget {
  const IncomeListScreen({super.key});

  @override
  State<IncomeListScreen> createState() => _IncomeListScreenState();
}

class _IncomeListScreenState extends State<IncomeListScreen> {
  final _searchCtl = TextEditingController();
  final _minAmountCtl = TextEditingController();
  final _maxAmountCtl = TextEditingController();
  final _tagCtl = TextEditingController();
  String _searchText = '';
  int? _filterCategoryId;
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

  List<IncomeModel> _applyFilters(List<IncomeModel> incomes) {
    var filtered = incomes;
    if (_searchText.isNotEmpty) {
      final q = _searchText.toLowerCase();
      filtered = filtered.where((e) {
        final source = (e.source ?? '').toLowerCase();
        final catName = (e.category?.name ?? '').toLowerCase();
        final tagStr = e.tags.join(' ').toLowerCase();
        final note = (e.note ?? '').toLowerCase();
        return source.contains(q) || catName.contains(q) || tagStr.contains(q) || note.contains(q);
      }).toList();
    }
    if (_filterCategoryId != null) {
      filtered = filtered.where((e) => e.categoryId == _filterCategoryId).toList();
    }
    if (_filterDateRange != null) {
      filtered = filtered.where((e) =>
        !e.date.isBefore(_filterDateRange!.start) && !e.date.isAfter(_filterDateRange!.end),
      ).toList();
    }
    if (_filterMinAmount != null) {
      filtered = filtered.where((e) => e.amount >= _filterMinAmount!).toList();
    }
    if (_filterMaxAmount != null) {
      filtered = filtered.where((e) => e.amount <= _filterMaxAmount!).toList();
    }
    if (_filterTag != null && _filterTag!.isNotEmpty) {
      filtered = filtered.where((e) =>
        e.tags.any((t) => t.toLowerCase().contains(_filterTag!.toLowerCase())),
      ).toList();
    }
    return filtered;
  }

  void _showFilters(BuildContext context, List<CategoryModel> categories) {
    _minAmountCtl.text = _filterMinAmount?.toStringAsFixed(2) ?? '';
    _maxAmountCtl.text = _filterMaxAmount?.toStringAsFixed(2) ?? '';
    _tagCtl.text = _filterTag ?? '';
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
    return BlocBuilder<IncomeBloc, IncomeState>(
      builder: (context, state) {
        final allIncomes = state.incomes;
        final categories = state.categories;
        final currencyFormat = context.watch<CurrencyCubit>().state.formatter;
        final dateFormat = DateFormat(DateFormats.display);

        final incomes = _applyFilters(allIncomes);
        final total = incomes.fold(0.0, (s, e) => s + e.amount);
        final hasFilters = _searchText.isNotEmpty ||
            _filterCategoryId != null ||
            _filterDateRange != null ||
            _filterMinAmount != null ||
            _filterMaxAmount != null ||
            _filterTag != null;

        return Scaffold(
          appBar: AppBar(title: const Text(PageTitles.allIncomes)),
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
                  Text('${incomes.length} incomes',
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
                child: incomes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(allIncomes.isEmpty ? Icons.trending_up : Icons.search_off,
                                size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              allIncomes.isEmpty
                                  ? 'No incomes yet. Tap + to add one!'
                                  : 'No incomes match your filters.',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          context.read<IncomeBloc>().add(LoadIncomes());
                          context.read<DashboardBloc>().add(LoadDashboard());
                        },
                        child: ListView.builder(
                          itemCount: incomes.length,
                          itemBuilder: (ctx, i) {
                            final e = incomes[i];
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
                                  title: const Text(UiLabels.deleteIncomeTitle),
                                  content: Text('Delete ${currencyFormat.format(e.amount)} income?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                  ],
                                ),
                              ),
                              onDismissed: (_) {
                                context.read<IncomeBloc>().add(DeleteIncomeEvent(e.id));
                                context.read<DashboardBloc>().add(LoadDashboard());
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Income deleted'),
                                    action: SnackBarAction(label: 'Undo', onPressed: () {
                                      context.read<IncomeBloc>().add(LoadIncomes());
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
                                        if (e.source != null) ...[
                                          const SizedBox(width: 6),
                                          Text('— ${e.source}', style: const TextStyle(color: Colors.grey)),
                                        ],
                                      ],
                                    ),
                                    if (e.tags.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Wrap(
                                          spacing: 4,
                                          children: e.tags.map((t) => Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.secondaryContainer,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(t, style: const TextStyle(fontSize: 10)),
                                          )).toList(),
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
          floatingActionButton: FloatingActionButton(
            onPressed: () => _addIncome(context),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _addIncome(BuildContext context) {
    Navigator.push<bool>(context, MaterialPageRoute(
      builder: (_) => const IncomeFormScreen(),
    )).then((changed) {
      if (changed == true && context.mounted) {
        context.read<IncomeBloc>().add(LoadIncomes());
        context.read<DashboardBloc>().add(LoadDashboard());
      }
    });
  }

  void _openEdit(BuildContext context, IncomeModel income) {
    Navigator.push<bool>(context, MaterialPageRoute(
      builder: (_) => IncomeFormScreen(income: income),
    )).then((changed) {
      if (changed == true && context.mounted) {
        context.read<IncomeBloc>().add(LoadIncomes());
        context.read<DashboardBloc>().add(LoadDashboard());
      }
    });
  }
}
