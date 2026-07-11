import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'data/database/app_database.dart';
import 'data/repositories/expense_repository.dart';
import 'domain/services/ai_insights_service.dart';
import 'blocs/theme_cubit.dart';
import 'blocs/currency_cubit.dart';
import 'blocs/auth_cubit.dart';
import 'blocs/expense_bloc.dart';
import 'blocs/income_bloc.dart';
import 'blocs/dashboard_bloc.dart';
import 'blocs/budget_bloc.dart';
import 'blocs/ai_bloc.dart';
import 'blocs/onboarding_cubit.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('[Main] starting app');
  final db = AppDatabase();
  await db.seedDefaultCategories();
  final repo = ExpenseRepository(db);
  final aiService = AIInsightsService();
  debugPrint('[Main] initialized - db & repo ready');

  debugPrint('[Main] generating recurring expenses');
  try { await repo.generateRecurringExpenses(); } catch (e) { debugPrint('[Main] recurring gen error: $e'); }

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: db),
        RepositoryProvider.value(value: repo),
        RepositoryProvider.value(value: aiService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ThemeCubit()),
          BlocProvider(create: (_) => CurrencyCubit()),
          BlocProvider(create: (_) => OnboardingCubit()),
          BlocProvider(create: (_) => AuthCubit()),
          BlocProvider(create: (_) => ExpenseBloc(repo)..add(LoadExpenses())),
          BlocProvider(create: (_) => IncomeBloc(repo)..add(LoadIncomes())),
          BlocProvider(create: (_) => DashboardBloc(repo)..add(LoadDashboard())),
          BlocProvider(create: (_) => BudgetBloc(repo)..add(LoadBudgets())),
          BlocProvider(create: (_) => AIBloc(repo, aiService)..add(LoadAIInsights())),
        ],
        child: const ExpenseTrackerApp(),
      ),
    ),
  );
}
