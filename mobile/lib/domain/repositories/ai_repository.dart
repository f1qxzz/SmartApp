abstract class AiRepository {
  Future<String> ask(String message);
  Future<String> summarizeChat(String chatId);
}
