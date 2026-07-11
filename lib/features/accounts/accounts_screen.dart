import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../data/models/expense_models.dart';
import '../../data/repositories/expense_repository.dart';
import '../../core/utils/icons_helper.dart';
import '../../blocs/dashboard_bloc.dart';
import 'account_form_screen.dart';
import 'transfer_screen.dart';
import 'account_detail_screen.dart';
import '../../blocs/currency_cubit.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  int _refreshKey = 0;

  Future<List<AccountModel>> _fetchAccounts() {
    return RepositoryProvider.of<ExpenseRepository>(context).getAccounts();
  }

  void _refresh() => setState(() => _refreshKey++);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = context.watch<CurrencyCubit>().state.formatter;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            tooltip: 'Transfer',
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const TransferScreen(),
            )).then((_) => _refresh()),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: PageTitles.addAccount,
            onPressed: () => _openForm(context),
          ),
        ],
      ),
      body: FutureBuilder<List<AccountModel>>(
        key: ValueKey(_refreshKey),
        future: _fetchAccounts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final accounts = snapshot.data ?? [];
          if (accounts.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_balance_wallet, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No accounts yet', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _openForm(context),
                    icon: const Icon(Icons.add),
                    label: const Text(PageTitles.addAccount),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final a = accounts[index];
              return Dismissible(
                key: ValueKey(a.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (_) => showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text(UiLabels.deleteAccountTitle),
                    content: Text('Are you sure you want to delete "${a.name}"?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ).then((confirmed) {
                  if (confirmed == true) {
                    debugPrint('[AccountsScreen] deleting account id=${a.id}, name=${a.name}');
                    RepositoryProvider.of<ExpenseRepository>(context).deleteAccount(a.id);
                    context.read<DashboardBloc>().add(LoadDashboard());
                    _refresh();
                    return true;
                  }
                  return false;
                }),
                child: a.isDebt ? _DebtAccountCard(a: a, currencyFormat: currencyFormat, onChanged: _refresh) : _AccountCard(a: a, currencyFormat: currencyFormat, onChanged: _refresh),
              );
            },
          );
        },
      ),
    );
  }

  void _openForm(BuildContext context, {AccountModel? account}) {
    debugPrint('[AccountsScreen] opening form${account != null ? " for account id=${account.id}" : " (new)"}');
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => AccountFormScreen(account: account),
    )).then((_) {
      debugPrint('[AccountsScreen] form returned, refreshing');
      _refresh();
      if (context.mounted) context.read<DashboardBloc>().add(LoadDashboard());
    });
  }
}

class _AccountCard extends StatelessWidget {
  final AccountModel a;
  final NumberFormat currencyFormat;
  final VoidCallback onChanged;
  const _AccountCard({required this.a, required this.currencyFormat, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(a.color).withValues(alpha: 0.2),
          child: Icon(iconFromString(a.icon), color: Color(a.color)),
        ),
        title: Text(a.name),
        subtitle: Text(a.type),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(currencyFormat.format(a.balance),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: a.balance >= 0 ? Colors.green : Colors.red,
                )),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => AccountFormScreen(account: a),
              )).then((_) {
                onChanged();
                if (context.mounted) context.read<DashboardBloc>().add(LoadDashboard());
              }),
            ),
          ],
        ),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => AccountDetailScreen(account: a),
        )).then((_) {
          onChanged();
          if (context.mounted) context.read<DashboardBloc>().add(LoadDashboard());
        }),
      ),
    );
  }
}

class _DebtAccountCard extends StatelessWidget {
  final AccountModel a;
  final NumberFormat currencyFormat;
  final VoidCallback onChanged;
  const _DebtAccountCard({required this.a, required this.currencyFormat, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final progress = a.progress;
    final isCreditCard = a.type == AccountTypes.creditCard;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => AccountDetailScreen(account: a),
        )).then((_) {
          onChanged();
          if (context.mounted) context.read<DashboardBloc>().add(LoadDashboard());
        }),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Color(a.color).withValues(alpha: 0.2),
                    child: Icon(iconFromString(a.icon), color: Color(a.color)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(a.type, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(currencyFormat.format(a.balance),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: a.balance >= 0 ? Colors.green : Colors.red,
                          )),
                      if (a.interestRate != null && a.interestRate! > 0)
                        Text('${a.interestRate!.toStringAsFixed(1)}% APR',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    ],
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => AccountFormScreen(account: a),
                    )).then((_) {
                      onChanged();
                      if (context.mounted) context.read<DashboardBloc>().add(LoadDashboard());
                    }),
                  ),
                ],
              ),
              if (progress != null && a.principal! > 0) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.red.shade100,
                    valueColor: AlwaysStoppedAnimation(progress < 1 ? Colors.red : Colors.green),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(isCreditCard
                        ? '${currencyFormat.format(a.principal! - a.balance.abs())} available'
                        : '${(progress * 100).toStringAsFixed(0)}% paid',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    const Spacer(),
                    if (a.minPayment != null && a.minPayment! > 0)
                      Text('Min: ${currencyFormat.format(a.minPayment!)}/mo',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
