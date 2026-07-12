import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'blocs/theme_cubit.dart';
import 'blocs/onboarding_cubit.dart';
import 'data/repositories/expense_repository.dart';
import 'features/splash/splash_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/expense/expense_form_screen.dart';
import 'features/analytics/analytics_screen.dart';
import 'features/budget/budget_screen.dart';
import 'features/ai_insights/ai_insights_screen.dart';
import 'features/auth/lock_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'generated/l10n/app_localizations.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return MaterialApp(
          title: AppMeta.name,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SplashScreen(
            child: BlocBuilder<OnboardingCubit, OnboardingState>(
              builder: (context, state) {
                if (state.loading) return const SizedBox.shrink();
                if (!state.completed) return const OnboardingScreen();
                return LockScreen(child: const MainShell());
              },
            ),
          ),
        );
      },
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  Timer? _recurringTimer;

  final screens = const [
    DashboardScreen(),
    AnalyticsScreen(),
    BudgetScreen(),
    AIInsightsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    debugPrint('[MainShell] initialized');
    _recurringTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      try {
        final repo = RepositoryProvider.of<ExpenseRepository>(context, listen: false);
        repo.generateRecurringExpenses();
        debugPrint('[MainShell] periodic recurring check completed');
      } catch (e) {
        debugPrint('[MainShell] periodic recurring error: $e');
      }
    });
  }

  @override
  void dispose() {
    _recurringTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) {
          debugPrint('[MainShell] tab changed to index $i');
          setState(() => _currentIndex = i);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: NavLabels.home),
          NavigationDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics), label: NavLabels.analytics),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: NavLabels.budget),
          NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome), label: NavLabels.insights),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: NavLabels.settings),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => _addExpense(context),
              icon: const Icon(Icons.add),
              label: const Text(NavLabels.add),
            )
          : null,
    );
  }

  void _addExpense(BuildContext context) {
    debugPrint('[MainShell] opening add expense form');
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => const ExpenseFormScreen(),
    ));
  }
}
