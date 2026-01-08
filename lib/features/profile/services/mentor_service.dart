import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';

class MentorService {
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  Future<String> getPersonalizedAdvice(String userQuery) async {
    if (userQuery.trim().isEmpty) {
      throw Exception('Please share what\'s on your mind');
    }

    Object? lastError;

    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final prompt = 'You are a compassionate mental health mentor.\n'
            'User says: "$userQuery"\n'
            'Respond empathetically with 2–3 practical steps.';

        final text = await _generateViaHttp(prompt);
        if (text.isNotEmpty) return text;

        throw Exception('Empty Gemini response');
      } catch (e) {
        lastError = e;
        print('Attempt ${attempt + 1} failed: $e');
        if (attempt < _maxRetries - 1) {
          await Future.delayed(_retryDelay);
        }
      }
    }

    throw Exception('Gemini failed: $lastError');
  }

  Future<String> _generateViaHttp(String prompt) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      'gemini-pro:generateContent?key=${ApiConfig.geminiApiKey}',
    );

    final body = {
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 512,
      }
    };

    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final candidates = data['candidates'] as List?;

    if (candidates == null || candidates.isEmpty) return '';

    final parts = candidates[0]['content']['parts'] as List?;
    if (parts == null || parts.isEmpty) return '';

    return (parts[0]['text'] as String?)?.trim() ?? '';
  }
}
