import 'package:smartlife_app/data/services/smarthome_service.dart';
import 'package:smartlife_app/domain/entities/smarthome_state.dart';
import 'package:smartlife_app/domain/repositories/smarthome_repository.dart';

class SmartHomeRepositoryImpl implements SmartHomeRepository {
  final SmartHomeService _service;

  SmartHomeRepositoryImpl(this._service);

  @override
  Future<SmartHomeState> getHomeState() async {
    return await _service.loadState();
  }

  @override
  Future<void> saveHomeState(SmartHomeState state) async {
    await _service.saveState(state);
  }
}
