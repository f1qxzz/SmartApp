import 'package:smartlife_app/core/storage/hive_service.dart';
import 'package:smartlife_app/domain/entities/smarthome_state.dart';

class SmartHomeService {
  static const String _storageKey = 'smarthome_state';

  Future<void> saveState(SmartHomeState state) async {
    await HiveService.putUserScopedAppValue(_storageKey, state.toJson());
  }

  Future<SmartHomeState> loadState() async {
    final Map<dynamic, dynamic>? data =
        HiveService.appBox.get(HiveService.userScopedAppKey(_storageKey));

    if (data == null) {
      return SmartHomeState.initial();
    }

    return SmartHomeState.fromJson(Map<String, dynamic>.from(data));
  }
}
