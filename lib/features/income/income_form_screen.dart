import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../data/models/expense_models.dart';
import '../../blocs/income_bloc.dart';
import '../../blocs/dashboard_bloc.dart';
import '../../core/utils/icons_helper.dart';
import '../../blocs/currency_cubit.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';

class IncomeFormScreen extends StatefulWidget {
  final IncomeModel? income;

  const IncomeFormScreen({super.key, this.income});

  @override
  State<IncomeFormScreen> createState() => _IncomeFormScreenState();
}

class _IncomeFormScreenState extends State<IncomeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountCtl;
  late TextEditingController _sourceCtl;
  late TextEditingController _noteCtl;
  late TextEditingController _tagsCtl;
  int? _categoryId;
  int? _accountId;
  DateTime _date = DateTime.now();
  bool _isSaving = false;

  bool get _isEditing => widget.income != null;

  @override
  void initState() {
    super.initState();
    final e = widget.income;
    _amountCtl = TextEditingController(text: e != null ? e.amount.toString() : '');
    _sourceCtl = TextEditingController(text: e?.source ?? '');
    _noteCtl = TextEditingController(text: e?.note ?? '');
    _tagsCtl = TextEditingController(text: e?.tags.isNotEmpty == true ? e!.tags.join(', ') : '');
    _categoryId = e?.categoryId;
    _accountId = e?.accountId;
    _date = e?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountCtl.dispose();
    _sourceCtl.dispose();
    _noteCtl.dispose();
    _tagsCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<IncomeBloc>().state;
    final categories = state.categories;
    final accounts = state.accounts;
    final symbol = context.watch<CurrencyCubit>().state.symbol;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? PageTitles.editIncome : PageTitles.addIncome),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _amountCtl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '$symbol ',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (double.tryParse(v) == null) return 'Invalid number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _categoryId,
              decoration: const InputDecoration(labelText: 'Category'),
              items: categories.map((c) => DropdownMenuItem(
                value: c.id,
                child: Row(children: [
                  Icon(iconFromString(c.icon), size: 20, color: Color(c.color)),
                  const SizedBox(width: 8),
                  Text(c.name),
                ]),
              )).toList(),
              onChanged: (v) {
                setState(() => _categoryId = v);
              },
              validator: (v) => v == null ? UiLabels.selectCategory : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _accountId,
              decoration: const InputDecoration(labelText: UiLabels.accountOptional),
              items: [
                const DropdownMenuItem(value: null, child: Text('None')),
                ...accounts.map((a) => DropdownMenuItem(
                  value: a.id,
                  child: Row(children: [
                    Icon(iconFromString(a.icon), size: 20, color: Color(a.color)),
                    const SizedBox(width: 8),
                    Text('${a.name} ($symbol${a.balance.toStringAsFixed(0)})'),
                  ]),
                )),
              ],
              onChanged: (v) => setState(() => _accountId = v),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text('Date: ${DateFormat.yMMMd().format(_date)}'),
              trailing: const Icon(Icons.edit),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sourceCtl,
              decoration: const InputDecoration(labelText: UiLabels.sourceOptional),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteCtl,
              decoration: const InputDecoration(labelText: UiLabels.noteOptional),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tagsCtl,
              decoration: const InputDecoration(
                labelText: UiLabels.tagsOptional,
                hintText: UiLabels.tagHintIncome,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save),
              label: Text(_isEditing ? 'Update' : 'Save'),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _isSaving ? null : _delete,
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final amount = double.parse(_amountCtl.text);
      if (_isEditing) {
        context.read<IncomeBloc>().add(UpdateIncomeEvent(
          id: widget.income!.id,
          amount: amount,
          categoryId: _categoryId,
          date: _date,
          source: _sourceCtl.text.isEmpty ? null : _sourceCtl.text,
          note: _noteCtl.text.isEmpty ? null : _noteCtl.text,
          accountId: _accountId,
          tags: _parseTags(),
        ));
      } else {
        context.read<IncomeBloc>().add(AddIncomeEvent(
          amount: amount,
          categoryId: _categoryId!,
          date: _date,
          source: _sourceCtl.text.isEmpty ? null : _sourceCtl.text,
          note: _noteCtl.text.isEmpty ? null : _noteCtl.text,
          accountId: _accountId,
          tags: _parseTags(),
        ));
      }
      context.read<DashboardBloc>().add(LoadDashboard());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? AppMessages.incomeUpdated : AppMessages.incomeAdded)),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _delete() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(UiLabels.deleteIncomeTitle),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        context.read<IncomeBloc>().add(DeleteIncomeEvent(widget.income!.id));
        context.read<DashboardBloc>().add(LoadDashboard());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppMessages.incomeDeleted)),
        );
        Navigator.pop(context, true);
      }
    });
  }

  List<String> _parseTags() {
    final raw = _tagsCtl.text;
    if (raw.trim().isEmpty) return const [];
    return raw.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
  }
}
