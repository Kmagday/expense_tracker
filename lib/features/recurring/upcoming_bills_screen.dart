import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/models/expense_models.dart';
import '../../core/utils/icons_helper.dart';
import '../../blocs/currency_cubit.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';

class UpcomingBillsScreen extends StatefulWidget {
  const UpcomingBillsScreen({super.key});

  @override
  State<UpcomingBillsScreen> createState() => _UpcomingBillsScreenState();
}

class _UpcomingBillsScreenState extends State<UpcomingBillsScreen> {
  List<ExpenseModel> _bills = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final repo = RepositoryProvider.of<ExpenseRepository>(context);
    final bills = await repo.getUpcomingBills();
    if (mounted) setState(() { _bills = bills; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final fmt = context.watch<CurrencyCubit>().state.formatter;
    return Scaffold(
      appBar: AppBar(title: const Text(PageTitles.upcomingBills)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _bills.isEmpty
              ? const Center(child: Text('No upcoming recurring bills'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    itemCount: _bills.length,
                    itemBuilder: (ctx, i) {
                      final b = _bills[i];
                      final now = DateTime.now();
                      final isPastDue = b.date.isBefore(DateTime(now.year, now.month, now.day));
                      final daysUntil = now.difference(b.date).inDays;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(b.category?.color ?? 0xFF757575).withValues(alpha: 0.2),
                          child: Icon(iconFromString(b.category?.icon ?? 'receipt'), size: 20,
                              color: Color(b.category?.color ?? 0xFF757575)),
                        ),
                        title: Text(b.category?.name ?? 'Other'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(DateFormat.yMMMd().format(b.date)),
                            if (b.tags.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Wrap(
                                  spacing: 4,
                                  children: b.tags.map((t) => Container(
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
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(fmt.format(b.amount), style: const TextStyle(fontWeight: FontWeight.w600)),
                            if (isPastDue)
                              Text('$daysUntil days overdue',
                                  style: const TextStyle(color: Colors.red, fontSize: 12))
                            else if (daysUntil == 0)
                              const Text('Due today', style: TextStyle(color: Colors.orange, fontSize: 12))
                            else
                              Text('${-daysUntil} days left',
                                  style: const TextStyle(color: Colors.green, fontSize: 12)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
