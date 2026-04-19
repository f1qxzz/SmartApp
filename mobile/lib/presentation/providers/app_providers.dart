import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartlife_app/core/network/dio_client.dart';
import 'package:smartlife_app/core/network/socket_client.dart';
import 'package:smartlife_app/data/repositories/ai_repository_impl.dart';
import 'package:smartlife_app/data/repositories/auth_repository_impl.dart';
import 'package:smartlife_app/data/repositories/chat_repository_impl.dart';
import 'package:smartlife_app/data/repositories/finance_repository_impl.dart';
import 'package:smartlife_app/data/repositories/user_repository_impl.dart';
import 'package:smartlife_app/data/services/ai_service.dart';
import 'package:smartlife_app/data/services/auth_service.dart';
import 'package:smartlife_app/data/services/chat_service.dart';
import 'package:smartlife_app/data/services/finance_service.dart';
import 'package:smartlife_app/data/services/user_service.dart';
import 'package:smartlife_app/data/services/life_hub_service.dart';
import 'package:smartlife_app/domain/repositories/ai_repository.dart';
import 'package:smartlife_app/domain/repositories/auth_repository.dart';
import 'package:smartlife_app/domain/repositories/chat_repository.dart';
import 'package:smartlife_app/domain/repositories/finance_repository.dart';
import 'package:smartlife_app/domain/repositories/user_repository.dart';
import 'package:smartlife_app/domain/repositories/life_hub_repository.dart';
import 'package:smartlife_app/data/repositories/life_hub_repository_impl.dart';
import 'package:smartlife_app/domain/usecases/ai_usecases.dart';
import 'package:smartlife_app/domain/usecases/auth_usecases.dart';
import 'package:smartlife_app/domain/usecases/chat_usecases.dart';
import 'package:smartlife_app/domain/usecases/finance_usecases.dart';

final dioClientProvider = Provider<DioClient>((ref) => DioClient());
final socketClientProvider = Provider<SocketClient>((ref) => SocketClient());

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.read(dioClientProvider));
});

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(ref.read(dioClientProvider), ref.read(socketClientProvider));
});

final financeServiceProvider = Provider<FinanceService>((ref) {
  return FinanceService(ref.read(dioClientProvider));
});

final aiServiceProvider = Provider<AiService>((ref) {
  return AiService(ref.read(dioClientProvider));
});

final userServiceProvider = Provider<UserService>((ref) {
  return UserService(ref.read(dioClientProvider));
});

final lifeHubServiceProvider = Provider<LifeHubService>((ref) {
  return LifeHubService(ref.read(dioClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.read(authServiceProvider));
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl(ref.read(chatServiceProvider));
});

final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  return FinanceRepositoryImpl(ref.read(financeServiceProvider));
});

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return AiRepositoryImpl(ref.read(aiServiceProvider));
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(ref.read(userServiceProvider));
});

final lifeHubRepositoryProvider = Provider<LifeHubRepository>((ref) {
  return LifeHubRepositoryImpl(ref.read(lifeHubServiceProvider));
});

final authUseCasesProvider = Provider<AuthUseCases>((ref) {
  return AuthUseCases(ref.read(authRepositoryProvider));
});

final chatUseCasesProvider = Provider<ChatUseCases>((ref) {
  return ChatUseCases(ref.read(chatRepositoryProvider));
});

final financeUseCasesProvider = Provider<FinanceUseCases>((ref) {
  return FinanceUseCases(ref.read(financeRepositoryProvider));
});

final aiUseCasesProvider = Provider<AiUseCases>((ref) {
  return AiUseCases(ref.read(aiRepositoryProvider));
});
