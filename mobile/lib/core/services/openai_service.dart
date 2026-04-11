import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:smartlife_app/core/config/openai_config.dart';
import 'package:smartlife_app/core/constants/app_constants.dart';
import 'package:smartlife_app/core/utils/app_formatters.dart';

class OpenAIServiceException implements Exception {
  final String message;

  OpenAIServiceException(this.message);

  @override
  String toString() => message;
}

class OpenAIService {
  OpenAIService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  void dispose() {
    _client.close();
  }

  Future<String> generateFinanceAnswer({
    required String userPrompt,
    required List<MockTransaction> transactions,
  }) async {
    if (!OpenAIConfig.isConfigured) {
      throw OpenAIServiceException('OPENAI_API_KEY belum diset.');
    }

    final Uri uri = Uri.parse('https://api.openai.com/v1/responses');
    final Map<String, dynamic> payload = <String, dynamic>{
      'model': OpenAIConfig.model,
      'temperature': 0.4,
      'max_output_tokens': 320,
      'instructions':
          'Kamu adalah asisten keuangan personal. Beri jawaban singkat, '
              'jelas, actionable, dan dalam Bahasa Indonesia.',
      'input': '''
Data transaksi user:
${_buildTransactionSummary(transactions)}

Pertanyaan user:
$userPrompt
''',
    };

    final http.Response response = await _client.post(
      uri,
      headers: <String, String>{
        'Authorization': 'Bearer ${OpenAIConfig.apiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode >= 400) {
      throw OpenAIServiceException(
        'OpenAI error ${response.statusCode}: ${_extractErrorMessage(response.body)}',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw OpenAIServiceException('Respons OpenAI tidak valid.');
    }

    final String text = _extractOutputText(decoded);
    if (text.trim().isEmpty) {
      throw OpenAIServiceException('OpenAI tidak mengembalikan teks jawaban.');
    }
    return text.trim();
  }

  String _buildTransactionSummary(List<MockTransaction> transactions) {
    if (transactions.isEmpty) {
      return 'Tidak ada transaksi.';
    }

    final double total = transactions.fold<double>(
      0,
      (double sum, MockTransaction tx) => sum + tx.amount,
    );

    final Map<String, double> byCategory = <String, double>{};
    for (final MockTransaction tx in transactions) {
      byCategory.update(
        tx.category,
        (double value) => value + tx.amount,
        ifAbsent: () => tx.amount,
      );
    }

    final List<String> topLines = byCategory.entries.map((entry) {
      final FinanceCategory category = financeCategories.firstWhere(
        (FinanceCategory item) => item.id == entry.key,
        orElse: () => financeCategories.last,
      );
      return '- ${category.name}: ${AppFormatters.currency(entry.value)}';
    }).toList()
      ..sort();

    final List<MockTransaction> sorted = List<MockTransaction>.from(transactions)
      ..sort((MockTransaction a, MockTransaction b) => b.date.compareTo(a.date));
    final List<MockTransaction> latest = sorted.take(5).toList();
    final List<String> latestLines = latest.map((MockTransaction tx) {
      final FinanceCategory category = financeCategories.firstWhere(
        (FinanceCategory item) => item.id == tx.category,
        orElse: () => financeCategories.last,
      );
      return '- ${category.name} | ${tx.description} | ${AppFormatters.currency(tx.amount)}';
    }).toList();

    return '''
Total pengeluaran: ${AppFormatters.currency(total)}
Jumlah transaksi: ${transactions.length}

Per kategori:
${topLines.join('\n')}

5 transaksi terbaru:
${latestLines.join('\n')}
''';
  }

  String _extractOutputText(Map<String, dynamic> payload) {
    final dynamic directText = payload['output_text'];
    if (directText is String && directText.trim().isNotEmpty) {
      return directText;
    }

    final dynamic output = payload['output'];
    if (output is! List) {
      return '';
    }

    final StringBuffer buffer = StringBuffer();
    for (final dynamic item in output) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      final dynamic content = item['content'];
      if (content is! List) {
        continue;
      }
      for (final dynamic contentItem in content) {
        if (contentItem is! Map<String, dynamic>) {
          continue;
        }
        final dynamic type = contentItem['type'];
        final dynamic text = contentItem['text'];
        if ((type == 'output_text' || type == 'text') && text is String) {
          if (buffer.isNotEmpty) {
            buffer.writeln();
          }
          buffer.write(text);
        }
      }
    }

    return buffer.toString();
  }

  String _extractErrorMessage(String rawBody) {
    try {
      final dynamic decoded = jsonDecode(rawBody);
      if (decoded is Map<String, dynamic>) {
        final dynamic error = decoded['error'];
        if (error is Map<String, dynamic>) {
          final dynamic message = error['message'];
          if (message is String && message.trim().isNotEmpty) {
            return message.trim();
          }
        }
      }
    } catch (_) {
      return rawBody;
    }

    return rawBody;
  }
}
