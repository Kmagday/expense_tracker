import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/expense_models.dart';
import '../../data/repositories/expense_repository.dart';
import '../../blocs/currency_cubit.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';

class AccountFormScreen extends StatefulWidget {
  final AccountModel? account;
  const AccountFormScreen({super.key, this.account});

  @override
  State<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends State<AccountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _balanceCtl = TextEditingController();
  String _type = 'Checking';
  String _icon = 'account_balance';
  int _color = 0xFF1E88E5;
  bool _isSaving = false;

  bool get _isEditing => widget.account != null;

  static const _types = ['Checking', AccountTypes.savings, 'Cash', DefaultAccounts.creditCard, AccountTypes.investment];
  static const _icons = ['account_balance', 'savings', 'credit_card', 'payments', 'wallet'];
  static const _colors = [
    0xFF1E88E5, 0xFF43A047, 0xFFE53935, 0xFFFB8C00, 0xFF8E24AA,
    0xFF00ACC1, 0xFF6D4C41, 0xFF546E7A,
  ];

  @override
  void initState() {
    super.initState();
    final a = widget.account;
    if (a != null) {
      _nameCtl.text = a.name;
      _balanceCtl.text = a.balance.toStringAsFixed(2);
      _type = _types.contains(a.type) ? a.type : _types.first;
      _icon = a.icon;
      _color = a.color;
    }
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _balanceCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final symbol = context.watch<CurrencyCubit>().state.symbol;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? PageTitles.editAccount : PageTitles.addAccount)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtl,
              decoration: const InputDecoration(labelText: 'Account Name'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 16),
            if (!_isEditing)
              TextFormField(
                controller: _balanceCtl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Initial Balance',
                  prefixText: '$symbol ',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Invalid number';
                  return null;
                },
              ),
            if (!_isEditing) const SizedBox(height: 16),
            Text('Icon', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _icons.map((icon) => ChoiceChip(
                label: Icon(_iconData(icon)),
                selected: _icon == icon,
                onSelected: (_) => setState(() => _icon = icon),
              )).toList(),
            ),
            const SizedBox(height: 16),
            Text('Color', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _colors.map((c) => GestureDetector(
                onTap: () => setState(() => _color = c),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Color(c),
                    shape: BoxShape.circle,
                    border: _color == c ? Border.all(color: Colors.white, width: 3) : null,
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save),
              label: Text(_isEditing ? 'Update' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconData(String name) {
    switch (name) {
      case 'account_balance': return Icons.account_balance;
      case 'savings': return Icons.savings;
      case 'credit_card': return Icons.credit_card;
      case 'payments': return Icons.payments;
      case 'wallet': return Icons.account_balance_wallet;
      default: return Icons.account_balance;
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final repo = RepositoryProvider.of<ExpenseRepository>(context);
      if (_isEditing) {
        await repo.updateAccount(
          widget.account!.id,
          name: _nameCtl.text.trim(),
          type: _type,
          icon: _icon,
          color: _color,
        );
      } else {
        final balance = double.tryParse(_balanceCtl.text) ?? 0;
        await repo.addAccount(
          _nameCtl.text.trim(),
          _type,
          icon: _icon,
          color: _color,
          balance: balance,
        );
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? AppMessages.accountUpdated : AppMessages.accountCreated)),
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
}
