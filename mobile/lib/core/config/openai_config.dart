class OpenAIConfig {
  static const String apiKey = String.fromEnvironment('OPENAI_API_KEY');
  static const String model =
      String.fromEnvironment('OPENAI_MODEL', defaultValue: 'gpt-4o-mini');

  static bool get isConfigured => apiKey.trim().isNotEmpty;
}
