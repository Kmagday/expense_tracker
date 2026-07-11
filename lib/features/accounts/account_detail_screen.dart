import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../data/models/expense_models.dart';
import '../../data/repositories/expense_repository.dart';
import '../../core/utils/icons_helper.dart';
import '../../blocs/currency_cubit.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';

class AccountDetailScreen extends StatelessWidget {
  final AccountModel account;
  const AccountDetailScreen({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = context.watch<CurrencyCubit>().state.formatter;
    final repo = RepositoryProvider.of<ExpenseRepository>(context);

    return Scaffold(
      appBar: AppBar(title: Text(account.name)),
      body: FutureBuilder(
        future: Future.wait([
          repo.getExpenses(accountId: account.id),
          repo.getIncomes(accountId: account.id),
          repo.getTransfersForAccount(account.id),
          repo.getAccounts(),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Failed to load'));
          }
          final expenses = snapshot.data![0] as List<ExpenseModel>;
          final incomes = snapshot.data![1] as List<IncomeModel>;
          final transfers = snapshot.data![2] as List<TransferModel>;
          final allAccounts = snapshot.data![3] as List<AccountModel>;
          final accountNames = {for (final a in allAccounts) a.id: a.name};

          if (expenses.isEmpty && incomes.isEmpty && transfers.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No transactions yet', style: theme.textTheme.titleMedium),
                ],
              ),
            );
          }

          final allItems = <_ActivityItem>[
            ...incomes.map((i) => _ActivityItem(
              date: i.date,
              title: i.category?.name ?? 'Income',
              amount: i.amount,
              icon: iconFromString(i.category?.icon ?? 'receipt'),
              color: Colors.green,
              isIncome: true,
            )),
            ...expenses.map((e) => _ActivityItem(
              date: e.date,
              title: e.category?.name ?? 'Expense',
              amount: e.amount,
              icon: iconFromString(e.category?.icon ?? 'receipt'),
              color: Colors.red,
              isIncome: false,
            )),
            ...transfers.map((t) {
              final isOut = t.fromAccountId == account.id;
              final otherName = accountNames[isOut ? t.toAccountId : t.fromAccountId] ?? 'Account';
              return _ActivityItem(
                date: t.date,
                title: isOut ? 'Transfer to $otherName' : 'Transfer from $otherName',
                amount: t.amount,
                icon: Icons.compare_arrows,
                color: isOut ? Colors.orange : Colors.blue,
                isIncome: !isOut,
              );
            }),
          ]..sort((a, b) => b.date.compareTo(a.date));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: allItems.length,
            itemBuilder: (context, index) {
              final item = allItems[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: item.color.withValues(alpha: 0.2),
                  child: Icon(item.icon, color: item.color, size: 20),
                ),
                title: Text(item.title),
                subtitle: Text(DateFormat(DateFormats.displayYear).format(item.date)),
                trailing: Text(
                  '${item.isIncome ? '+' : '-'}${currencyFormat.format(item.amount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: item.isIncome ? Colors.green : Colors.red,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ActivityItem {
  final DateTime date;
  final String title;
  final double amount;
  final IconData icon;
  final Color color;
  final bool isIncome;
  _ActivityItem({
    required this.date, required this.title, required this.amount,
    required this.icon, required this.color, required this.isIncome,
  });
}
