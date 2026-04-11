import 'package:smartlife_app/data/services/ai_service.dart';
import 'package:smartlife_app/domain/repositories/ai_repository.dart';

class AiRepositoryImpl implements AiRepository {
  AiRepositoryImpl(this._aiService);

  final AiService _aiService;

  @override
  Future<String> ask(String message) => _aiService.ask(message);
}
