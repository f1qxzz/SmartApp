import 'package:smartlife_app/domain/repositories/ai_repository.dart';

class AiUseCases {
  AiUseCases(this._repository);

  final AiRepository _repository;

  Future<String> ask(String message) => _repository.ask(message);
}
