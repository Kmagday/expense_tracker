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
  final _principalCtl = TextEditingController();
  final _interestCtl = TextEditingController();
  final _minPaymentCtl = TextEditingController();
  DateTime? _dueDate;
  String _type = 'Checking';
  String _icon = 'account_balance';
  int _color = 0xFF1E88E5;
  bool _isSaving = false;

  bool get _isEditing => widget.account != null;
  bool get _isDebtType =>
      _type == AccountTypes.creditCard ||
      _type == AccountTypes.loan ||
      _type == AccountTypes.personLoan;

  static const _types = [
    'Checking', AccountTypes.savings, 'Cash',
    AccountTypes.creditCard, AccountTypes.loan,
    AccountTypes.personLoan, AccountTypes.investment,
  ];
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
      if (a.principal != null) _principalCtl.text = a.principal!.toStringAsFixed(2);
      if (a.interestRate != null) _interestCtl.text = a.interestRate!.toStringAsFixed(1);
      if (a.minPayment != null) _minPaymentCtl.text = a.minPayment!.toStringAsFixed(2);
      _dueDate = a.dueDate;
    }
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _balanceCtl.dispose();
    _principalCtl.dispose();
    _interestCtl.dispose();
    _minPaymentCtl.dispose();
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
            if (!_isDebtType)
              TextFormField(
                controller: _balanceCtl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: _isEditing ? 'Current Balance' : 'Initial Balance',
                  prefixText: '$symbol ',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Invalid number';
                  return null;
                },
              ),
            if (!_isDebtType) const SizedBox(height: 16),

            if (_isDebtType) ...[
              if (!_isEditing || _principalCtl.text.isNotEmpty)
                TextFormField(
                  controller: _principalCtl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: _type == AccountTypes.creditCard ? 'Credit Limit' : 'Loan Amount',
                    prefixText: '$symbol ',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (double.tryParse(v) == null) return 'Invalid number';
                    return null;
                  },
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _interestCtl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Interest Rate (%)',
                  suffixText: '%',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _minPaymentCtl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Minimum Payment',
                  prefixText: '$symbol ',
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Due Date'),
                subtitle: Text(_dueDate != null
                    ? '${_dueDate!.month}/${_dueDate!.day}/${_dueDate!.year}'
                    : 'Not set'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dueDate ?? DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (picked != null) setState(() => _dueDate = picked);
                },
              ),
              const SizedBox(height: 16),
            ],

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
    debugPrint('[AccountForm] ${_isEditing ? "updating" : "saving"} account - name: ${_nameCtl.text}, type: $_type, isDebt: $_isDebtType');
    try {
      final repo = RepositoryProvider.of<ExpenseRepository>(context);
      if (_isEditing) {
        debugPrint('[AccountForm] updating account id=${widget.account!.id}');
        await repo.updateAccount(
          widget.account!.id,
          name: _nameCtl.text.trim(),
          type: _type,
          icon: _icon,
          color: _color,
          balance: _isDebtType ? null : double.tryParse(_balanceCtl.text),
          principal: _principalCtl.text.isNotEmpty ? double.tryParse(_principalCtl.text) : null,
          interestRate: _interestCtl.text.isNotEmpty ? double.tryParse(_interestCtl.text) : null,
          minPayment: _minPaymentCtl.text.isNotEmpty ? double.tryParse(_minPaymentCtl.text) : null,
          dueDate: _dueDate,
        );
      } else {
        final parsedPrincipal = double.tryParse(_principalCtl.text);
        double balance;
        if (_isDebtType) {
          balance = _type == AccountTypes.creditCard
              ? 0
              : -(parsedPrincipal ?? 0);
        } else {
          balance = double.tryParse(_balanceCtl.text) ?? 0;
        }
        debugPrint('[AccountForm] creating new account');
        await repo.addAccount(
          _nameCtl.text.trim(),
          _type,
          icon: _icon,
          color: _color,
          balance: balance,
          principal: parsedPrincipal,
          interestRate: _interestCtl.text.isNotEmpty ? double.tryParse(_interestCtl.text) : null,
          minPayment: _minPaymentCtl.text.isNotEmpty ? double.tryParse(_minPaymentCtl.text) : null,
          dueDate: _dueDate,
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
