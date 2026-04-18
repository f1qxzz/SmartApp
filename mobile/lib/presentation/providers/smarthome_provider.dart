import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartlife_app/domain/entities/smarthome_state.dart';
import 'package:smartlife_app/domain/repositories/smarthome_repository.dart';
import 'package:smartlife_app/presentation/providers/app_providers.dart';

final smartHomeProvider =
    StateNotifierProvider<SmartHomeNotifier, SmartHomeState>((ref) {
  return SmartHomeNotifier(ref.read(smartHomeRepositoryProvider));
});

class SmartHomeNotifier extends StateNotifier<SmartHomeState> {
  final SmartHomeRepository _repository;

  SmartHomeNotifier(this._repository) : super(SmartHomeState.initial()) {
    loadState();
  }

  Future<void> loadState() async {
    final state = await _repository.getHomeState();
    this.state = state;
  }

  Future<void> toggleMainLight(bool value) async {
    state = state.copyWith(isMainLightOn: value);
    await _repository.saveHomeState(state);
  }

  Future<void> setLightBrightness(double value) async {
    state = state.copyWith(lightBrightness: value);
    await _repository.saveHomeState(state);
  }

  Future<void> toggleAc() async {
    state = state.copyWith(isAcOn: !state.isAcOn);
    await _repository.saveHomeState(state);
  }

  Future<void> updateAcTemp(double value) async {
    state = state.copyWith(acTemp: value);
    await _repository.saveHomeState(state);
  }

  Future<void> toggleDoorLock() async {
    state = state.copyWith(isDoorLocked: !state.isDoorLocked);
    await _repository.saveHomeState(state);
  }

  Future<void> toggleCctv() async {
    state = state.copyWith(isCctvActive: !state.isCctvActive);
    await _repository.saveHomeState(state);
  }
}
