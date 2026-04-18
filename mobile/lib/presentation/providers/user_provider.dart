import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartlife_app/domain/entities/user_entity.dart';
import 'package:smartlife_app/presentation/providers/app_providers.dart';

class UserState {
  final List<UserEntity> users;
  final bool isLoading;
  final String? error;

  UserState({
    this.users = const [],
    this.isLoading = false,
    this.error,
  });

  UserState copyWith({
    List<UserEntity>? users,
    bool? isLoading,
    String? error,
  }) {
    return UserState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class UserNotifier extends StateNotifier<UserState> {
  UserNotifier(this._ref) : super(UserState());

  final Ref _ref;

  Future<void> fetchUsers({String? search}) async {
    state = state.copyWith(isLoading: true);
    try {
      final repo = _ref.read(userRepositoryProvider);
      final users = await repo.getUsers(search: search);
      state = state.copyWith(users: users, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateRole(String userId, String role) async {
    state = state.copyWith(isLoading: true);
    try {
      final repo = _ref.read(userRepositoryProvider);
      final updatedUser = await repo.updateUserRole(userId, role);
      
      final newUsers = state.users.map((u) {
        return u.id == updatedUser.id ? updatedUser : u;
      }).toList();

      state = state.copyWith(users: newUsers, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier(ref);
});
