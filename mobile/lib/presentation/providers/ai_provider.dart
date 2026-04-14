import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartlife_app/domain/entities/ai_message_entity.dart';
import 'package:smartlife_app/domain/usecases/ai_usecases.dart';
import 'package:smartlife_app/presentation/providers/app_providers.dart';
import 'package:smartlife_app/presentation/providers/auth_provider.dart';

class AiState {
  final List<AiMessageEntity> messages;
  final bool isLoading;
  final String? errorMessage;

  const AiState({
    this.messages = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  AiState copyWith({
    List<AiMessageEntity>? messages,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AiState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AiNotifier extends StateNotifier<AiState> {
  AiNotifier(this._useCases) : super(const AiState()) {
    _setWelcome();
  }

  final AiUseCases _useCases;

  void _setWelcome() {
    if (state.messages.isNotEmpty) return;

    state = state.copyWith(
      messages: [
        AiMessageEntity(
          text:
              'Halo! Saya SmartLife AI. Tanyakan apa saja tentang kondisi finansialmu.',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ],
    );
  }

  Future<void> ask(String question) async {
    final cleanQuestion = question.trim();
    if (cleanQuestion.isEmpty || state.isLoading) {
      return;
    }

    final nextMessages = List<AiMessageEntity>.from(state.messages)
      ..add(
        AiMessageEntity(
          text: cleanQuestion,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );

    state = state.copyWith(
        messages: nextMessages, isLoading: true, clearError: true);

    try {
      final answer = await _useCases.ask(cleanQuestion);
      final updated = List<AiMessageEntity>.from(state.messages)
        ..add(
          AiMessageEntity(
            text: answer,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );

      state = state.copyWith(messages: updated, isLoading: false);
    } catch (error) {
      final fallback = List<AiMessageEntity>.from(state.messages)
        ..add(
          AiMessageEntity(
            text: 'Maaf, AI belum bisa merespons saat ini. Coba lagi sebentar.',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );

      state = state.copyWith(
        messages: fallback,
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  void clearConversation() {
    state = const AiState();
    _setWelcome();
  }

  void reset() {
    state = const AiState();
    _setWelcome();
  }
}

final aiProvider = StateNotifierProvider<AiNotifier, AiState>((ref) {
  final notifier = AiNotifier(ref.read(aiUseCasesProvider));

  ref.listen<AuthState>(authProvider, (previous, next) {
    if (!next.isAuthenticated) {
      notifier.reset();
      return;
    }
    if (previous?.user?.id != next.user?.id) {
      notifier.reset();
    }
  });

  return notifier;
});
