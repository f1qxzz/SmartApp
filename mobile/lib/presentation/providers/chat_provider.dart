import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartlife_app/domain/entities/chat_conversation_entity.dart';
import 'package:smartlife_app/domain/entities/chat_message_entity.dart';
import 'package:smartlife_app/domain/usecases/chat_usecases.dart';
import 'package:smartlife_app/presentation/providers/app_providers.dart';
import 'package:smartlife_app/presentation/providers/auth_provider.dart';

class ChatState {
  final bool isLoading;
  final String? errorMessage;
  final List<ChatConversationEntity> chats;
  final List<ChatConversationEntity> searchResults;
  final Map<String, List<ChatMessageEntity>> messagesByChatId;
  final Map<String, bool> typingFrom;
  final String? activeChatId;

  const ChatState({
    this.isLoading = false,
    this.errorMessage,
    this.chats = const [],
    this.searchResults = const [],
    this.messagesByChatId = const {},
    this.typingFrom = const {},
    this.activeChatId,
  });

  ChatState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<ChatConversationEntity>? chats,
    List<ChatConversationEntity>? searchResults,
    Map<String, List<ChatMessageEntity>>? messagesByChatId,
    Map<String, bool>? typingFrom,
    String? activeChatId,
    bool clearError = false,
  }) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      chats: chats ?? this.chats,
      searchResults: searchResults ?? this.searchResults,
      messagesByChatId: messagesByChatId ?? this.messagesByChatId,
      typingFrom: typingFrom ?? this.typingFrom,
      activeChatId: activeChatId ?? this.activeChatId,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier(this._useCases) : super(const ChatState());

  final ChatUseCases _useCases;

  StreamSubscription<ChatMessageEntity>? _messageSub;
  StreamSubscription<Map<String, dynamic>>? _typingSub;
  StreamSubscription<Map<String, dynamic>>? _presenceSub;
  StreamSubscription<Map<String, dynamic>>? _readSub;

  String? _connectedToken;

  Future<void> onAuthChanged(AuthState authState) async {
    if (!authState.isAuthenticated || authState.token == null) {
      disconnect();
      state = const ChatState();
      return;
    }

    if (_connectedToken == authState.token) {
      return;
    }

    _connectedToken = authState.token;
    _useCases.connectSocket(authState.token!);
    _bindSocketStreams();

    await refreshChats();
  }

  Future<void> refreshChats() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final chats = await _useCases.getConversations();
      state = state.copyWith(
        isLoading: false,
        chats: chats,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> searchUsers(String keyword) async {
    final query = keyword.trim();
    if (query.isEmpty) {
      state = state.copyWith(searchResults: const []);
      return;
    }

    try {
      final users = await _useCases.searchUsers(query);
      final chatsByUser = {
        for (final chat in state.chats) chat.userId: chat,
      };

      final merged = users.map((user) {
        final existing = chatsByUser[user.userId];
        if (existing == null) {
          return user;
        }
        return user.copyWith(
          chatId: existing.chatId,
          lastMessage: existing.lastMessage,
          updatedAt: existing.updatedAt,
          unreadCount: existing.unreadCount,
        );
      }).toList();

      state = state.copyWith(searchResults: merged);
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
    }
  }

  Future<void> loadMessages(String chatId) async {
    final normalizedChatId = chatId.trim();
    if (normalizedChatId.isEmpty) {
      return;
    }

    try {
      final messages = await _useCases.getMessages(normalizedChatId);
      final map =
          Map<String, List<ChatMessageEntity>>.from(state.messagesByChatId);
      map[normalizedChatId] = messages;

      state = state.copyWith(
        messagesByChatId: map,
        activeChatId: normalizedChatId,
      );
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
    }
  }

  Future<ChatMessageEntity> sendMessage({
    required String text,
    String? chatId,
    String? receiverId,
  }) async {
    final normalizedText = text.trim();
    if (normalizedText.isEmpty) {
      throw Exception('Pesan tidak boleh kosong');
    }

    final message = await _useCases.sendMessage(
      text: normalizedText,
      chatId: chatId,
      receiverId: receiverId,
    );

    _appendMessage(message);
    await _refreshChatsSilent();
    return message;
  }

  void setTyping({
    required String toUserId,
    required bool isTyping,
  }) {
    if (toUserId.trim().isEmpty) {
      return;
    }
    _useCases.emitTyping(toUserId: toUserId, isTyping: isTyping);
  }

  bool isTypingFrom(String userId) => state.typingFrom[userId] == true;

  List<ChatMessageEntity> messagesOfChat(String chatId) =>
      state.messagesByChatId[chatId] ?? const [];

  void setActiveChat(String? chatId) {
    state = state.copyWith(activeChatId: chatId ?? '');
  }

  Future<void> _refreshChatsSilent() async {
    try {
      final chats = await _useCases.getConversations();
      state = state.copyWith(chats: chats);
    } catch (_) {
      // no-op
    }
  }

  void _appendMessage(ChatMessageEntity message) {
    if (message.chatId.trim().isEmpty) {
      return;
    }

    final map =
        Map<String, List<ChatMessageEntity>>.from(state.messagesByChatId);
    final list = List<ChatMessageEntity>.from(map[message.chatId] ?? const []);

    final exists = list.any((item) => item.id == message.id);
    if (!exists) {
      list.add(message);
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      map[message.chatId] = list;
      state = state.copyWith(messagesByChatId: map);
    }
  }

  void _bindSocketStreams() {
    _messageSub?.cancel();
    _typingSub?.cancel();
    _presenceSub?.cancel();
    _readSub?.cancel();

    _messageSub = _useCases.onNewMessage().listen((message) async {
      _appendMessage(message);
      await _refreshChatsSilent();
    });

    _typingSub = _useCases.onTyping().listen((event) {
      final fromUserId = (event['fromUserId'] ?? '').toString();
      final isTyping = event['isTyping'] == true;
      if (fromUserId.isEmpty) {
        return;
      }

      final typing = Map<String, bool>.from(state.typingFrom);
      typing[fromUserId] = isTyping;
      state = state.copyWith(typingFrom: typing);
    });

    _presenceSub = _useCases.onPresence().listen((_) async {
      await _refreshChatsSilent();
    });

    _readSub = _useCases.onRead().listen((_) {});
  }

  void disconnect() {
    _connectedToken = null;
    _messageSub?.cancel();
    _typingSub?.cancel();
    _presenceSub?.cancel();
    _readSub?.cancel();
    _messageSub = null;
    _typingSub = null;
    _presenceSub = null;
    _readSub = null;
    _useCases.disconnectSocket();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final notifier = ChatNotifier(ref.read(chatUseCasesProvider));

  ref.listen<AuthState>(authProvider, (previous, next) {
    notifier.onAuthChanged(next);
  });

  notifier.onAuthChanged(ref.read(authProvider));
  return notifier;
});
