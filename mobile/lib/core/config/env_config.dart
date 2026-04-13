import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:5000';
  static String get socketUrl => dotenv.env['SOCKET_URL'] ?? apiBaseUrl;
  static String? get googleWebClientId {
    final value = dotenv.env['GOOGLE_WEB_CLIENT_ID']?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  static double get monthlyBudget {
    final raw = dotenv.env['MONTHLY_BUDGET'];
    return double.tryParse(raw ?? '') ?? 5000000;
  }
}
