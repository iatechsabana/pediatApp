import 'dart:convert';
import 'package:http/http.dart' as http;

/// Simple OpenAI Chat Completions client. Sends a single user message and
/// returns the assistant content. Requires a valid OpenAI API key.
Future<String> fetchOpenAIReply(String apiKey, String userMessage) async {
  final url = Uri.parse('https://api.openai.com/v1/chat/completions');
  final body = jsonEncode({
    'model': 'gpt-3.5-turbo',
    'messages': [
      {'role': 'user', 'content': userMessage}
    ],
    'temperature': 0.7,
    'max_tokens': 600,
  });

  final resp = await http.post(url, headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $apiKey',
  }, body: body).timeout(const Duration(seconds: 30));

  if (resp.statusCode == 200) {
    final Map<String, dynamic> j = jsonDecode(resp.body);
    final choices = j['choices'] as List<dynamic>?;
    if (choices != null && choices.isNotEmpty) {
      final message = choices[0]['message'] as Map<String, dynamic>?;
      if (message != null && message['content'] != null) {
        return (message['content'] as String).trim();
      }
    }
    throw Exception('Respuesta inválida del servidor');
  } else {
    // Try to surface useful error
    String msg = 'Status ${resp.statusCode}';
    try {
      final bodyJson = jsonDecode(resp.body);
      if (bodyJson is Map && bodyJson['error'] != null) {
        msg = bodyJson['error']['message'] ?? msg;
      }
    } catch (_) {}
    throw Exception('OpenAI error: $msg');
  }
}
