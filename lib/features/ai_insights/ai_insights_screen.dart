import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/ai_bloc.dart';
import '../../blocs/expense_bloc.dart';
import '../../core/utils/icons_helper.dart';
import '../../blocs/currency_cubit.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';

class AIInsightsScreen extends StatefulWidget {
  const AIInsightsScreen({super.key});

  @override
  State<AIInsightsScreen> createState() => _AIInsightsScreenState();
}

class _AIInsightsScreenState extends State<AIInsightsScreen> {
  final _chatCtl = TextEditingController();
  final _scrollCtl = ScrollController();

  @override
  void dispose() {
    _chatCtl.dispose();
    _scrollCtl.dispose();
    super.dispose();
  }

  void _sendMessage(AIBloc bloc) {
    final msg = _chatCtl.text.trim();
    if (msg.isEmpty) return;
    bloc.add(ChatWithAI(msg));
    _chatCtl.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtl.hasClients) {
        _scrollCtl.animateTo(_scrollCtl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AIBloc, AIState>(
      builder: (context, state) {
        final forecast = state.forecast;
        debugPrint('[AIInsights] build - isLoading: ${state.isLoading}, forecast: \$$forecast, anomalies: ${state.anomalies.length}');
        final anomalies = state.anomalies;
        final subscriptions = state.subscriptions;
        final patterns = state.patterns;
        final suggestions = state.suggestions;
        final theme = Theme.of(context);
        final currencyFormat = context.watch<CurrencyCubit>().state.formatter;
        final now = DateTime.now();
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

        final expenses = context.read<ExpenseBloc>().state.expenses;
        final monthExpenses = expenses.where((e) =>
          e.date.month == now.month && e.date.year == now.year
        ).toList();
        final totalSoFar = monthExpenses.fold(0.0, (s, e) => s + e.amount);
        final dayOfMonth = now.day;

        return Scaffold(
          appBar: AppBar(title: const Text(PageTitles.insights)),
          body: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  controller: _scrollCtl,
                  padding: const EdgeInsets.all(16),
                  children: [
                    _SectionCard(
                      icon: Icons.trending_up, iconColor: Colors.blue,
                      title: 'End-of-Month Forecast',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Projected: ${currencyFormat.format(forecast)}',
                              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          _ForecastRow(
                            label: 'Spent so far', amount: totalSoFar,
                            color: Colors.grey, currencyFormat: currencyFormat,
                          ),
                          _ForecastRow(
                            label: 'Recurring (fixed)',
                            amount: monthExpenses.where((e) => e.isRecurring).fold(0.0, (s, e) => s + e.amount),
                            color: Colors.teal, currencyFormat: currencyFormat,
                          ),
                          _ForecastRow(
                            label: 'Variable (projected)',
                            amount: forecast - monthExpenses.where((e) => e.isRecurring).fold(0.0, (s, e) => s + e.amount),
                            color: Colors.orange, currencyFormat: currencyFormat,
                          ),
                          const SizedBox(height: 4),
                          Text('Day $dayOfMonth of $daysInMonth',
                              style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    _SectionCard(
                      icon: Icons.warning_amber, iconColor: Colors.red,
                      title: 'Unusual Expenses',
                      child: anomalies.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text('No unusual expenses detected this month.',
                                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                            )
                          : Column(
                              children: anomalies.take(3).map((e) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(iconFromString(e.category?.icon ?? 'receipt'), size: 16,
                                        color: Color(e.category?.color ?? 0xFF757575)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text('${e.category?.name ?? 'Other'} — '
                                          '${DateFormat.MMMd().format(e.date)}',
                                          style: theme.textTheme.bodySmall),
                                    ),
                                    Text(currencyFormat.format(e.amount),
                                        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                                  ],
                                ),
                              )).toList(),
                            ),
                    ),
                    const SizedBox(height: 12),

                    _SectionCard(
                      icon: Icons.analytics, iconColor: Colors.amber,
                      title: 'Spending Patterns',
                      child: patterns['highestSpendingDay'] == null
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text('Add more expenses to see spending patterns.',
                                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _PatternRow(
                                  icon: Icons.arrow_upward, color: Colors.red,
                                  text: 'Highest: ${patterns['highestSpendingDay']} '
                                      '(${currencyFormat.format(patterns['highestSpendingAmount'])})',
                                ),
                                const SizedBox(height: 4),
                                _PatternRow(
                                  icon: Icons.arrow_downward, color: Colors.green,
                                  text: 'Lowest: ${patterns['lowestSpendingDay']} '
                                      '(${currencyFormat.format(patterns['lowestSpendingAmount'])})',
                                ),
                                if (patterns['weekendPremiumPercent'] is double) ...[
                                  const SizedBox(height: 4),
                                  _PatternRow(
                                    icon: patterns['weekendSpendingHigher'] == true
                                        ? Icons.trending_up : Icons.trending_down,
                                    color: patterns['weekendSpendingHigher'] == true
                                        ? Colors.orange : Colors.green,
                                    text: patterns['weekendSpendingHigher'] == true
                                        ? 'Spend ${(patterns['weekendPremiumPercent'] as double).toStringAsFixed(0)}% '
                                            'more on weekends'
                                        : 'Weekend spending is lower than weekdays',
                                  ),
                                ],
                                if (patterns['dailyAverages'] != null) ...[
                                  const Divider(),
                                  Text('Daily averages:', style: theme.textTheme.bodySmall),
                                  const SizedBox(height: 4),
                                  ...(patterns['dailyAverages'] as Map<String, dynamic>).entries.map((e) =>
                                    _PatternRow(
                                      icon: Icons.circle, color: Colors.grey,
                                      text: '${e.key}: ${currencyFormat.format((e.value as num).toDouble())}',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                    ),
                    const SizedBox(height: 12),

                    _SectionCard(
                      icon: Icons.repeat, iconColor: Colors.teal,
                      title: 'Detected Subscriptions',
                      child: subscriptions.length < 2
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text('No recurring subscriptions detected yet.',
                                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                            )
                          : Column(
                              children: [
                                ...subscriptions.take(5).map((e) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Icon(iconFromString(e.category?.icon ?? 'receipt'), size: 16,
                                          color: Color(e.category?.color ?? 0xFF757575)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(e.category?.name ?? 'Other',
                                            style: theme.textTheme.bodySmall),
                                      ),
                                      Text(currencyFormat.format(e.amount),
                                          style: const TextStyle(fontWeight: FontWeight.w600)),
                                      if (e.note != null) ...[
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text('(${e.note})',
                                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                                              overflow: TextOverflow.ellipsis),
                                        ),
                                      ],
                                    ],
                                  ),
                                )),
                                if (subscriptions.length > 5)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text('+ ${subscriptions.length - 5} more',
                                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                                  ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 12),

                    _SectionCard(
                      icon: Icons.lightbulb, iconColor: Colors.green,
                      title: 'Saving Suggestions',
                      child: suggestions.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text('Add more expenses to get personalized suggestions.',
                                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                            )
                          : Column(
                              children: suggestions.map((s) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('• ', style: const TextStyle(fontWeight: FontWeight.bold)),
                                Expanded(child: Text(s, style: theme.textTheme.bodyMedium)),
                              ],
                            ),
                          )).toList(),
                        ),
                    ),
                    const SizedBox(height: 16),

                    _SectionCard(
                      icon: Icons.chat, iconColor: Colors.purple,
                      title: 'AI Chat Assistant',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Spacer(),
                              if (state.chatMessages.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18),
                                  tooltip: 'Clear chat',
                                  onPressed: () => context.read<AIBloc>().add(ClearChat()),
                                ),
                            ],
                          ),
                          SizedBox(
                            height: 300,
                            child: state.chatMessages.isEmpty
                                ? Center(
                                    child: Text(
                                      'Ask questions about your spending in natural language.\n'
                                      'Example: "How much did I spend on food last week?"',
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: state.chatMessages.length,
                                    itemBuilder: (ctx, i) {
                                        final msg = state.chatMessages[i];
                                        return Align(
                                          alignment: msg.isUser
                                              ? Alignment.centerRight
                                              : Alignment.centerLeft,
                                          child: Container(
                                            margin: const EdgeInsets.only(bottom: 8),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: msg.isUser
                                                  ? Theme.of(context).colorScheme.primaryContainer
                                                  : Colors.grey.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(12).copyWith(
                                                bottomRight: msg.isUser
                                                    ? Radius.zero : null,
                                                bottomLeft: msg.isUser
                                                    ? null : Radius.zero,
                                              ),
                                            ),
                                            constraints: BoxConstraints(
                                                maxWidth: MediaQuery.of(context).size.width * 0.75),
                                            child: Text(msg.text, style: theme.textTheme.bodySmall),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                            const SizedBox(height: 8),
                            if (state.isChatLoading)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    SizedBox(width: 16, height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2)),
                                    SizedBox(width: 8),
                                    Text('Thinking...', style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _chatCtl,
                                    decoration: InputDecoration(
                                      hintText: 'Ask about your finances...',
                                      border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12)),
                                      contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                    ),
                                    onSubmitted: (v) {
                                      if (v.trim().isNotEmpty) {
                                        _sendMessage(context.read<AIBloc>());
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.send),
                                  color: Theme.of(context).colorScheme.primary,
                                  onPressed: state.isChatLoading
                                      ? null
                                      : () => _sendMessage(context.read<AIBloc>()),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
      },
    );
  }
}

class _ForecastRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final NumberFormat currencyFormat;
  const _ForecastRow({
    required this.label,
    required this.amount,
    required this.color,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const Spacer(),
          Text(currencyFormat.format(amount),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _PatternRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _PatternRow({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 12),
              Text(title, style: theme.textTheme.titleSmall),
            ]),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
