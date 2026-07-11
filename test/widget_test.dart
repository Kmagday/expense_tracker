import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/data/database/app_database.dart';
import 'package:expense_tracker/data/repositories/expense_repository.dart';
import 'package:expense_tracker/domain/services/ai_insights_service.dart';
import 'package:expense_tracker/blocs/theme_cubit.dart';
import 'package:expense_tracker/blocs/currency_cubit.dart';
import 'package:expense_tracker/blocs/onboarding_cubit.dart';
import 'package:expense_tracker/blocs/auth_cubit.dart';
import 'package:expense_tracker/blocs/expense_bloc.dart';
import 'package:expense_tracker/blocs/income_bloc.dart';
import 'package:expense_tracker/blocs/dashboard_bloc.dart';
import 'package:expense_tracker/blocs/budget_bloc.dart';
import 'package:expense_tracker/blocs/ai_bloc.dart';
import 'package:expense_tracker/app.dart';
import 'package:expense_tracker/features/onboarding/onboarding_screen.dart';
import 'package:drift/native.dart';

void main() {
  testWidgets('App renders with bottom navigation when onboarding completed', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_completed': true});
    final db = AppDatabase.connect(NativeDatabase.memory());
    await db.seedDefaultCategories();
    final repo = ExpenseRepository(db);
    final aiService = AIInsightsService();

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(value: repo),
          RepositoryProvider.value(value: aiService),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => ThemeCubit()),
            BlocProvider(create: (_) => CurrencyCubit()),
            BlocProvider(create: (_) => OnboardingCubit()),
            BlocProvider(create: (_) => AuthCubit()),
            BlocProvider(create: (_) => ExpenseBloc(repo)),
            BlocProvider(create: (_) => IncomeBloc(repo)),
            BlocProvider(create: (_) => DashboardBloc(repo)),
            BlocProvider(create: (_) => BudgetBloc(repo)),
            BlocProvider(create: (_) => AIBloc(repo, aiService)),
          ],
          child: const ExpenseTrackerApp(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Home'), findsWidgets);
    expect(find.text('Analytics'), findsWidgets);
  });

  testWidgets('Onboarding screen shows on first launch', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => OnboardingCubit()),
      ],
      child: const MaterialApp(home: OnboardingScreen()),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Track Your Expenses'), findsOneWidget);
  });
}
