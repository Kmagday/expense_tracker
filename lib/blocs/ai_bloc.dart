import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/models/expense_models.dart';
import '../data/repositories/expense_repository.dart';
import '../domain/services/ai_insights_service.dart';

// ── Events ──

sealed class AIEvent {}

final class LoadAIInsights extends AIEvent {}

final class ChatWithAI extends AIEvent {
  final String message;
  ChatWithAI(this.message);
}

final class ClearChat extends AIEvent {}

// ── Chat Message Model ──

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  ChatMessage({required this.text, required this.isUser, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();
}

// ── State ──

class AIState {
  final double forecast;
  final List<ExpenseModel> anomalies;
  final Map<String, dynamic> patterns;
  final List<String> suggestions;
  final List<ExpenseModel> subscriptions;
  final bool isLoading;
  final bool isChatLoading;
  final List<ChatMessage> chatMessages;

  const AIState({
    this.forecast = 0,
    this.anomalies = const [],
    this.patterns = const {},
    this.suggestions = const [],
    this.subscriptions = const [],
    this.isLoading = false,
    this.isChatLoading = false,
    this.chatMessages = const [],
  });

  AIState copyWith({
    double? forecast,
    List<ExpenseModel>? anomalies,
    Map<String, dynamic>? patterns,
    List<String>? suggestions,
    List<ExpenseModel>? subscriptions,
    bool? isLoading,
    bool? isChatLoading,
    List<ChatMessage>? chatMessages,
  }) {
    return AIState(
      forecast: forecast ?? this.forecast,
      anomalies: anomalies ?? this.anomalies,
      patterns: patterns ?? this.patterns,
      suggestions: suggestions ?? this.suggestions,
      subscriptions: subscriptions ?? this.subscriptions,
      isLoading: isLoading ?? this.isLoading,
      isChatLoading: isChatLoading ?? this.isChatLoading,
      chatMessages: chatMessages ?? this.chatMessages,
    );
  }
}

// ── Bloc ──

class AIBloc extends Bloc<AIEvent, AIState> {
  final ExpenseRepository _repo;
  final AIInsightsService _service;

  AIBloc(this._repo, this._service) : super(const AIState()) {
    on<LoadAIInsights>(_onLoad);
    on<ChatWithAI>(_onChat);
    on<ClearChat>(_onClearChat);
  }

  Future<void> _onLoad(LoadAIInsights event, Emitter<AIState> emit) async {
    debugPrint('[AIBloc] loading AI insights');
    emit(state.copyWith(isLoading: true));
    try {
      final expenses = await _repo.getExpenses();
      final now = DateTime.now();
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final monthExpenses = expenses.where((e) =>
        e.date.month == now.month && e.date.year == now.year,
      ).toList();

      final forecast = _service.forecastEndOfMonth(monthExpenses, daysInMonth, allExpenses: expenses);
      final anomalies = _service.detectAnomalies(expenses);
      final patterns = _service.analyzePatterns(expenses);
      final suggestions = _service.generateSuggestions(expenses);
      final subscriptions = _service.detectSubscriptions(expenses);
      debugPrint('[AIBloc] loaded - forecast: \$$forecast, anomalies: ${anomalies.length}, subscriptions: ${subscriptions.length}, suggestions: ${suggestions.length}');

      emit(state.copyWith(
        forecast: forecast,
        anomalies: anomalies,
        patterns: patterns,
        subscriptions: subscriptions,
        suggestions: suggestions,
        isLoading: false,
      ));
    } catch (e) {
      debugPrint('[AIBloc] _onLoad error: $e');
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> _onChat(ChatWithAI event, Emitter<AIState> emit) async {
    debugPrint('[AIBloc] chat requested: "${event.message}"');
    final userMsg = ChatMessage(text: event.message, isUser: true);
    emit(state.copyWith(
      isChatLoading: true,
      chatMessages: [...state.chatMessages, userMsg],
    ));

    try {
      final reply = await _service.chatWithAI(event.message, _repo);
      debugPrint('[AIBloc] chat reply received: ${reply.length} chars');
      emit(state.copyWith(
        isChatLoading: false,
        chatMessages: [...state.chatMessages, ChatMessage(text: reply, isUser: false)],
      ));
    } catch (e) {
      debugPrint('[AIBloc] _onChat error: $e');
      emit(state.copyWith(
        isChatLoading: false,
        chatMessages: [...state.chatMessages, ChatMessage(text: 'Error: $e', isUser: false)],
      ));
    }
  }

  void _onClearChat(ClearChat event, Emitter<AIState> emit) {
    debugPrint('[AIBloc] clearing chat');
    emit(state.copyWith(chatMessages: []));
  }
}
