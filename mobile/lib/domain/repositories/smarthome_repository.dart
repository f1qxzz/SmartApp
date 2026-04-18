import 'package:smartlife_app/domain/entities/smarthome_state.dart';

abstract class SmartHomeRepository {
  Future<SmartHomeState> getHomeState();
  Future<void> saveHomeState(SmartHomeState state);
}
