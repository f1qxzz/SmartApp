import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartlife_app/core/notifications/notification_service.dart';
import 'package:smartlife_app/core/storage/hive_boxes.dart';
import 'package:smartlife_app/core/storage/hive_service.dart';
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
  final String searchKeyword;
  final Map<String, List<ChatMessageEntity>> messagesByChatId;
  final Map<String, bool> typingFrom;
  final String? activeChatId;
  final ChatMessageEntity? replyMessage;

  const ChatState({
    this.isLoading = false,
    this.errorMessage,
    this.chats = const [],
    this.searchResults = const [],
    this.searchKeyword = '',
    this.messagesByChatId = const {},
    this.typingFrom = const {},
    this.activeChatId,
    this.replyMessage,
  });

  ChatState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<ChatConversationEntity>? chats,
    List<ChatConversationEntity>? searchResults,
    String? searchKeyword,
    Map<String, List<ChatMessageEntity>>? messagesByChatId,
    Map<String, bool>? typingFrom,
    String? activeChatId,
    ChatMessageEntity? replyMessage,
    bool clearError = false,
    bool clearReply = false,
  }) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      chats: chats ?? this.chats,
      searchResults: searchResults ?? this.searchResults,
      searchKeyword: searchKeyword ?? this.searchKeyword,
      messagesByChatId: messagesByChatId ?? this.messagesByChatId,
      typingFrom: typingFrom ?? this.typingFrom,
      activeChatId: activeChatId ?? this.activeChatId,
      replyMessage: clearReply ? null : (replyMessage ?? this.replyMessage),
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
  StreamSubscription<Map<String, dynamic>>? _reactionSub;
  int _searchRequestId = 0;

  String? _connectedToken;
  String? _currentUserId;

  Future<void> onAuthChanged(AuthState authState) async {
    if (!authState.isAuthenticated || authState.token == null) {
      disconnect();
      _currentUserId = null;
      state = const ChatState();
      return;
    }

    _currentUserId = authState.user?.id;

    if (_connectedToken == authState.token) {
      return;
    }

    _connectedToken = authState.token;
    _useCases.connectSocket(authState.token!);
    _bindSocketStreams();

    // Ensure notifications are initialized and permissions requested
    await NotificationService.instance.initialize();

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
    final requestId = ++_searchRequestId;

    if (query.isEmpty) {
      state = state.copyWith(
        searchResults: const [],
        searchKeyword: '',
      );
      return;
    }

    final List<ChatConversationEntity> localMatches = state.chats
        .where(
          (chat) => chat.username.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();

    state = state.copyWith(
      searchResults: localMatches,
      searchKeyword: query,
      clearError: true,
    );

    try {
      final users = await _useCases.searchUsers(query);
      if (requestId != _searchRequestId) {
        return;
      }
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

      state = state.copyWith(
        searchResults: merged,
        searchKeyword: query,
        clearError: true,
      );
    } catch (error) {
      if (requestId != _searchRequestId) {
        return;
      }
      state = state.copyWith(
        // Keep local fallback results when API search fails.
        searchResults: localMatches,
        searchKeyword: query,
        errorMessage: localMatches.isEmpty ? error.toString() : null,
        clearError: localMatches.isNotEmpty,
      );
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
    String type = 'text',
    String? attachmentUrl,
    String? replyToId,
  }) async {
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final targetChatId = (chatId != null && chatId.isNotEmpty) ? chatId : (receiverId ?? 'unknown');

    // Create optimistic message
    final tempMessage = ChatMessageEntity(
      id: tempId,
      chatId: targetChatId,
      senderId: _currentUserId ?? 'me',
      senderUsername: '',
      senderAvatar: '',
      text: text,
      type: type,
      attachmentUrl: attachmentUrl ?? '',
      createdAt: DateTime.now(),
      replyToId: replyToId,
      replyToMessage: state.replyMessage,
    );

    // Append immediately for instant real-time feel
    _appendMessage(tempMessage);
    state = state.copyWith(clearReply: true);

    try {
      final message = await _useCases.sendMessage(
        text: text,
        chatId: chatId,
        receiverId: receiverId,
        type: type,
        attachmentUrl: attachmentUrl,
        replyToId: replyToId,
      );

      // Replace temp message with the real one from server
      final map = Map<String, List<ChatMessageEntity>>.from(state.messagesByChatId);
      final cId = message.chatId.isNotEmpty ? message.chatId : targetChatId;
      final list = List<ChatMessageEntity>.from(map[cId] ?? const []);
      
      final index = list.indexWhere((m) => m.id == tempId);
      if (index != -1) {
        list[index] = message;
      } else {
        list.add(message); // fallback
      }
      map[cId] = list;
      
      state = state.copyWith(messagesByChatId: map);
      await _refreshChatsSilent();
      return message;
    } catch (error) {
      // Revert optimistic update on failure
      final map = Map<String, List<ChatMessageEntity>>.from(state.messagesByChatId);
      final list = List<ChatMessageEntity>.from(map[targetChatId] ?? const []);
      list.removeWhere((m) => m.id == tempId);
      map[targetChatId] = list;
      
      state = state.copyWith(messagesByChatId: map, errorMessage: error.toString());
      rethrow;
    }
  }

  Future<void> addReaction(String messageId, String emoji) async {
    final activeChatId = state.activeChatId;
    if (activeChatId == null || _currentUserId == null) return;

    try {
      // Optimistic Update
      _updateMessageReaction(activeChatId, messageId, _currentUserId!, emoji);
      
      await _useCases.addReaction(
        chatId: activeChatId,
        messageId: messageId,
        emoji: emoji,
      );
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
    }
  }

  Future<void> sendMediaMessage({
    required File file,
    String? text,
    required String chatId,
    required String type,
    String? replyToId,
  }) async {
    final tempId = 'temp_media_${DateTime.now().millisecondsSinceEpoch}';
    final targetChatId = chatId.isNotEmpty ? chatId : 'unknown';

    // Create optimistic message with LOCAL path
    final tempMessage = ChatMessageEntity(
      id: tempId,
      chatId: targetChatId,
      senderId: _currentUserId ?? 'me',
      senderUsername: '',
      senderAvatar: '',
      text: text ?? '',
      type: type,
      attachmentUrl: file.path, // Store local path for instant preview
      createdAt: DateTime.now(),
      replyToId: replyToId,
      replyToMessage: state.replyMessage,
    );

    _appendMessage(tempMessage);
    state = state.copyWith(clearReply: true);

    try {
      // 1. Upload in background
      final remoteUrl = await uploadFile(file);

      // 2. Finalize sending
      final message = await _useCases.sendMessage(
        text: text ?? '',
        chatId: chatId,
        type: type,
        attachmentUrl: remoteUrl,
        replyToId: replyToId,
      );

      // 3. Replace temp message
      final map = Map<String, List<ChatMessageEntity>>.from(state.messagesByChatId);
      final cId = message.chatId.isNotEmpty ? message.chatId : targetChatId;
      final list = List<ChatMessageEntity>.from(map[cId] ?? const []);
      
      final index = list.indexWhere((m) => m.id == tempId);
      if (index != -1) {
        list[index] = message;
      } else {
        list.add(message);
      }
      map[cId] = list;
      
      state = state.copyWith(messagesByChatId: map);
      await _refreshChatsSilent();
    } catch (error) {
      // Revert on failure
      final map = Map<String, List<ChatMessageEntity>>.from(state.messagesByChatId);
      final list = List<ChatMessageEntity>.from(map[targetChatId] ?? const []);
      list.removeWhere((m) => m.id == tempId);
      map[targetChatId] = list;
      
      state = state.copyWith(messagesByChatId: map, errorMessage: 'Gagal mengupload media: $error');
    }
  }

  void setReplyMessage(ChatMessageEntity? message) {
    state = state.copyWith(replyMessage: message);
  }

  void clearReplyMessage() {
    state = state.copyWith(clearReply: true);
  }

  Future<String> uploadFile(File file) => _useCases.uploadFile(file);

  Future<void> deleteMessage(String messageId, String chatId, {bool forEveryone = true}) async {
    try {
      if (forEveryone) {
        await _useCases.deleteMessage(messageId);
      }

      // Optimistic/Local update
      final map =
          Map<String, List<ChatMessageEntity>>.from(state.messagesByChatId);
      final list = List<ChatMessageEntity>.from(map[chatId] ?? const []);
      list.removeWhere((m) => m.id == messageId);
      map[chatId] = list;

      state = state.copyWith(messagesByChatId: map);
      await _refreshChatsSilent();
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
    }
  }

  Future<void> deleteConversation(String chatId) async {
    try {
      await _useCases.deleteConversation(chatId);

      // Remove from list
      final chats = List<ChatConversationEntity>.from(state.chats);
      chats.removeWhere((c) => c.chatId == chatId);

      final map =
          Map<String, List<ChatMessageEntity>>.from(state.messagesByChatId);
      map.remove(chatId);

      state = state.copyWith(
        chats: chats,
        messagesByChatId: map,
      );
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
    }
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

  void _updateMessageReaction(
    String chatId,
    String messageId,
    String userId,
    String emoji,
  ) {
    final map = Map<String, List<ChatMessageEntity>>.from(state.messagesByChatId);
    final list = List<ChatMessageEntity>.from(map[chatId] ?? const []);

    final index = list.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      final msg = list[index];
      final reactions = Map<String, String>.from(msg.reactions ?? {});
      
      if (reactions[userId] == emoji) {
        reactions.remove(userId);
      } else {
        reactions[userId] = emoji;
      }

      list[index] = msg.copyWith(reactions: reactions);
      map[chatId] = list;
      state = state.copyWith(messagesByChatId: map);
    }
  }

  void _bindSocketStreams() {
    _messageSub?.cancel();
    _typingSub?.cancel();
    _presenceSub?.cancel();
    _readSub?.cancel();
    _reactionSub?.cancel();

    _messageSub = _useCases.onNewMessage().listen((message) async {
      final fromOtherUser =
          _currentUserId != null && message.senderId != _currentUserId;
      final activeChatId = state.activeChatId?.trim() ?? '';
      final isCurrentChatOpen =
          activeChatId.isNotEmpty && activeChatId == message.chatId;

      if (fromOtherUser && !isCurrentChatOpen) {
        final bool chatNotifEnabled = HiveService.getUserScopedAppBool(
          HiveBoxes.prefChatNotifications,
          userId: _currentUserId ?? '',
          fallback: true,
        );

        if (chatNotifEnabled) {
          await NotificationService.instance.showChatMessage(message);
        }
      }

      _appendMessage(message);
      await _refreshChatsSilent();
    });

    _typingSub = _useCases.onTyping().listen((event) {
      final fromUserId = (event['fromUserId'] ?? '').toString();
      final isTyping = event['isTyping'] == true;
      
      // Ignore if it's from current user to prevent "echo" on their screen
      if (fromUserId.isEmpty || fromUserId == _currentUserId) {
        return;
      }

      final typing = Map<String, bool>.from(state.typingFrom);
      typing[fromUserId] = isTyping;
      state = state.copyWith(typingFrom: typing);
    });

    _presenceSub = _useCases.onPresence().listen((_) async {
      await _refreshChatsSilent();
      final activeSearchKeyword = state.searchKeyword.trim();
      if (activeSearchKeyword.isNotEmpty) {
        await searchUsers(activeSearchKeyword);
      }
    });

    _readSub = _useCases.onRead().listen((_) {});

    _reactionSub = _useCases.onReaction().listen((event) {
      final chatId = event['chatId']?.toString();
      final messageId = event['messageId']?.toString();
      final userId = event['userId']?.toString();
      final emoji = event['emoji']?.toString();

      if (chatId != null && messageId != null && userId != null && emoji != null) {
        _updateMessageReaction(chatId, messageId, userId, emoji);
      }
    });
  }

  void disconnect() {
    _connectedToken = null;
    _currentUserId = null;
    _messageSub?.cancel();
    _typingSub?.cancel();
    _presenceSub?.cancel();
    _readSub?.cancel();
    _reactionSub?.cancel();
    _messageSub = null;
    _typingSub = null;
    _presenceSub = null;
    _readSub = null;
    _reactionSub = null;
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
