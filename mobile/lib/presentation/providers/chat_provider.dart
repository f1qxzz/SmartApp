import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartlife_app/domain/entities/chat_conversation_entity.dart';
import 'package:smartlife_app/domain/entities/chat_message_entity.dart';
import 'package:smartlife_app/domain/usecases/chat_usecases.dart';
import 'package:smartlife_app/presentation/providers/app_providers.dart';
import 'package:smartlife_app/presentation/providers/auth_provider.dart';

class ChatState {
  final bool isLoading;
  final String? errorMessage;
  final List<ChatConversationEntity> conversations;
  final List<ChatConversationEntity> contacts;
  final Map<String, List<ChatMessageEntity>> messagesByContact;
  final Map<String, bool> typingFrom;
  final String? activeContactId;

  const ChatState({
    this.isLoading = false,
    this.errorMessage,
    this.conversations = const [],
    this.contacts = const [],
    this.messagesByContact = const {},
    this.typingFrom = const {},
    this.activeContactId,
  });

  ChatState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<ChatConversationEntity>? conversations,
    List<ChatConversationEntity>? contacts,
    Map<String, List<ChatMessageEntity>>? messagesByContact,
    Map<String, bool>? typingFrom,
    String? activeContactId,
    bool clearError = false,
  }) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      conversations: conversations ?? this.conversations,
      contacts: contacts ?? this.contacts,
      messagesByContact: messagesByContact ?? this.messagesByContact,
      typingFrom: typingFrom ?? this.typingFrom,
      activeContactId: activeContactId ?? this.activeContactId,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier(this._ref, this._useCases) : super(const ChatState());

  final Ref _ref;
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

    await refreshAll();
  }

  Future<void> refreshAll() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final results = await Future.wait([
        _useCases.getConversations(),
        _useCases.getContacts(),
      ]);
      final conversations = results[0] as List<ChatConversationEntity>;
      final contacts = results[1] as List<ChatConversationEntity>;

      state = state.copyWith(
        isLoading: false,
        conversations: conversations,
        contacts: _mergeContactsWithConversationState(
          conversations: conversations,
          contacts: contacts,
        ),
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }

  Future<void> loadMessages(String contactId) async {
    try {
      final messages = await _useCases.getMessages(contactId);
      final map = Map<String, List<ChatMessageEntity>>.from(state.messagesByContact);
      map[contactId] = messages;

      state = state.copyWith(
        messagesByContact: map,
        activeContactId: contactId,
      );

      await _useCases.markAsRead(contactId);
      await _refreshConversationsSilent();
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
    }
  }

  Future<void> sendMessage({required String receiverId, required String text}) async {
    if (text.trim().isEmpty) {
      return;
    }

    try {
      final message = await _useCases.sendMessage(receiverId: receiverId, text: text.trim());
      _appendMessage(message);
      await _refreshConversationsSilent();
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
      rethrow;
    }
  }

  Future<void> sendImage({required String receiverId, required File imageFile}) async {
    try {
      final imageUrl = await _useCases.uploadImage(imageFile);
      final message = await _useCases.sendMessage(receiverId: receiverId, image: imageUrl);
      _appendMessage(message);
      await _refreshConversationsSilent();
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
      rethrow;
    }
  }

  void setTyping({required String toUserId, required bool isTyping}) {
    _useCases.emitTyping(toUserId: toUserId, isTyping: isTyping);
  }

  bool isTypingFrom(String contactId) => state.typingFrom[contactId] == true;

  List<ChatMessageEntity> messagesOf(String contactId) =>
      state.messagesByContact[contactId] ?? const [];

  Future<void> _refreshConversationsSilent() async {
    try {
      final conversations = await _useCases.getConversations();
      state = state.copyWith(
        conversations: conversations,
        contacts: _mergeContactsWithConversationState(
          conversations: conversations,
          contacts: state.contacts,
        ),
      );
    } catch (_) {
      // ignore silent refresh failures
    }
  }

  List<ChatConversationEntity> _mergeContactsWithConversationState({
    required List<ChatConversationEntity> conversations,
    required List<ChatConversationEntity> contacts,
  }) {
    final map = <String, ChatConversationEntity>{
      for (final item in conversations) item.contactId: item,
    };

    return contacts.map((contact) {
      final existing = map[contact.contactId];
      if (existing == null) {
        return contact;
      }
      return ChatConversationEntity(
        contactId: contact.contactId,
        name: contact.name,
        email: contact.email,
        avatar: contact.avatar,
        isOnline: existing.isOnline,
        lastMessage: existing.lastMessage,
        lastTimestamp: existing.lastTimestamp,
        unreadCount: existing.unreadCount,
      );
    }).toList();
  }

  void _appendMessage(ChatMessageEntity message) {
    final currentUserId = _ref.read(authProvider).user?.id ?? '';
    final contactId = message.senderId == currentUserId ? message.receiverId : message.senderId;

    final map = Map<String, List<ChatMessageEntity>>.from(state.messagesByContact);
    final list = List<ChatMessageEntity>.from(map[contactId] ?? const []);

    final exists = list.any((item) => item.id == message.id);
    if (!exists) {
      list.add(message);
      list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      map[contactId] = list;
      state = state.copyWith(messagesByContact: map);
    }
  }

  void _bindSocketStreams() {
    _messageSub?.cancel();
    _typingSub?.cancel();
    _presenceSub?.cancel();
    _readSub?.cancel();

    _messageSub = _useCases.onNewMessage().listen((message) async {
      _appendMessage(message);
      await _refreshConversationsSilent();
    });

    _typingSub = _useCases.onTyping().listen((event) {
      final fromUserId = (event['fromUserId'] ?? '').toString();
      final isTyping = event['isTyping'] == true;

      if (fromUserId.isEmpty) return;

      final typingMap = Map<String, bool>.from(state.typingFrom);
      typingMap[fromUserId] = isTyping;
      state = state.copyWith(typingFrom: typingMap);
    });

    _presenceSub = _useCases.onPresence().listen((_) async {
      await _refreshConversationsSilent();
    });

    _readSub = _useCases.onRead().listen((event) {
      final byUserId = (event['byUserId'] ?? '').toString();
      if (byUserId.isEmpty) return;

      final map = Map<String, List<ChatMessageEntity>>.from(state.messagesByContact);
      final list = List<ChatMessageEntity>.from(map[byUserId] ?? const []);

      final currentUserId = _ref.read(authProvider).user?.id ?? '';
      map[byUserId] = list
          .map((item) => item.senderId == currentUserId ? item.copyWith(readStatus: true) : item)
          .toList();

      state = state.copyWith(messagesByContact: map);
    });
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
  final notifier = ChatNotifier(ref, ref.read(chatUseCasesProvider));

  ref.listen<AuthState>(authProvider, (previous, next) {
    notifier.onAuthChanged(next);
  });

  notifier.onAuthChanged(ref.read(authProvider));
  return notifier;
});
