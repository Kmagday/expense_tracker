import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/expense_models.dart';
import '../../data/repositories/expense_repository.dart';
import '../../core/utils/icons_helper.dart';
import '../../blocs/dashboard_bloc.dart';
import 'account_form_screen.dart';
import 'transfer_screen.dart';
import 'account_detail_screen.dart';
import '../../blocs/currency_cubit.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

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
            )),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: PageTitles.addAccount,
            onPressed: () => _openForm(context),
          ),
        ],
      ),
      body: FutureBuilder<List<AccountModel>>(
        future: RepositoryProvider.of<ExpenseRepository>(context).getAccounts(),
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
                    RepositoryProvider.of<ExpenseRepository>(context).deleteAccount(a.id);
                    context.read<DashboardBloc>().add(LoadDashboard());
                    return true;
                  }
                  return false;
                }),
                child: Card(
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
                          onPressed: () => _openForm(context, account: a),
                        ),
                      ],
                    ),
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => AccountDetailScreen(account: a),
                    )).then((_) {
                      if (context.mounted) {
                        context.read<DashboardBloc>().add(LoadDashboard());
                      }
                    }),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openForm(BuildContext context, {AccountModel? account}) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => AccountFormScreen(account: account),
    )).then((_) {
      if (context.mounted) {
        context.read<DashboardBloc>().add(LoadDashboard());
      }
    });
  }
}
