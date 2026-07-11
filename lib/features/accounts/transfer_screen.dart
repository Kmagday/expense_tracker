import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../data/models/expense_models.dart';
import '../../data/repositories/expense_repository.dart';
import '../../core/utils/icons_helper.dart';
import '../../blocs/dashboard_bloc.dart';
import '../../blocs/currency_cubit.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtl = TextEditingController();
  final _noteCtl = TextEditingController();
  int? _fromAccountId;
  int? _toAccountId;
  DateTime _date = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _amountCtl.dispose();
    _noteCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final symbol = context.watch<CurrencyCubit>().state.symbol;

    return Scaffold(
      appBar: AppBar(title: const Text(PageTitles.transfer)),
      body: FutureBuilder<List<AccountModel>>(
        future: RepositoryProvider.of<ExpenseRepository>(context).getAccounts(),
        builder: (context, snapshot) {
          final accounts = snapshot.data ?? [];
          return Form(
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
                    if (double.tryParse(v) == null || double.parse(v) <= 0) return 'Invalid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _fromAccountId,
                  decoration: const InputDecoration(labelText: 'From Account'),
                  items: accounts.map((a) => DropdownMenuItem(
                    value: a.id,
                    child: Row(children: [
                      Icon(iconFromString(a.icon), size: 20, color: Color(a.color)),
                      const SizedBox(width: 8),
                      Text('${a.name} ($symbol${a.balance.toStringAsFixed(0)})'),
                    ]),
                  )).toList(),
                  onChanged: (v) => setState(() {
                    _fromAccountId = v;
                    if (_toAccountId == v) _toAccountId = null;
                  }),
                  validator: (v) => v == null ? 'Select source account' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _toAccountId,
                  decoration: const InputDecoration(labelText: 'To Account'),
                  items: accounts
                      .where((a) => a.id != _fromAccountId)
                      .map((a) => DropdownMenuItem(
                        value: a.id,
                        child: Row(children: [
                          Icon(iconFromString(a.icon), size: 20, color: Color(a.color)),
                          const SizedBox(width: 8),
                          Text('${a.name} ($symbol${a.balance.toStringAsFixed(0)})'),
                        ]),
                      )).toList(),
                  onChanged: (v) => setState(() => _toAccountId = v),
                  validator: (v) => v == null ? 'Select destination account' : null,
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
                  controller: _noteCtl,
                  decoration: const InputDecoration(labelText: UiLabels.noteOptional),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.compare_arrows),
                  label: const Text('Transfer'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final amount = double.parse(_amountCtl.text);
      final repo = RepositoryProvider.of<ExpenseRepository>(context);
      await repo.addTransfer(
        fromAccountId: _fromAccountId!,
        toAccountId: _toAccountId!,
        amount: amount,
        date: _date,
        note: _noteCtl.text.isEmpty ? null : _noteCtl.text,
      );
      if (context.mounted) {
        context.read<DashboardBloc>().add(LoadDashboard());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transferred ${context.read<CurrencyCubit>().state.symbol}${amount.toStringAsFixed(2)}')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transfer failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
