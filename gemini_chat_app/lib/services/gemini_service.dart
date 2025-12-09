import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/message.dart';

class GeminiService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  String get _apiKey {
    final key = dotenv.env['GEMINI_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('Falta la variable de entorno GEMINI_API_KEY');
    }
    return key;
  }

  /// Envia el historial (limitado) para que Gemini tenga contexto.
  Future<String> sendMessage(List<Message> messages) async {
    try {
      final url = Uri.parse('$_baseUrl?key=$_apiKey');

      // 1) Mensaje actual (ultimo que escribio el usuario)
      final currentMessage = messages.last;

      // 2) Historial previo sin el actual
      final history = messages.sublist(0, messages.length - 1);

      // 3) Limitamos a los ultimos 3 mensajes previos
      final recentHistory = history.length > 3
          ? history.sublist(history.length - 3)
          : history;

      // 4) Contexto final a enviar (3 previos + actual)
      final contextToSend = [...recentHistory, currentMessage];

      // 5) Mapeamos al formato que espera Gemini
      final contents = contextToSend.map((msg) {
        return {
          'role': msg.isUser ? 'user' : 'model',
          'parts': [
            {'text': msg.text},
          ],
        };
      }).toList();

      final body = jsonEncode({
        'contents': contents,
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 8192,
          'topP': 0.8,
          'topK': 40,
        },
      });

      // Hacemos la petición POST a la API de Gemini
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data == null ||
            data['candidates'] == null ||
            data['candidates'].isEmpty) {
          throw Exception('Respuesta inválida de Gemini: ${response.body}');
        }

        final candidate = data['candidates'][0];

        if (candidate['content'] == null) {
          throw Exception(
            'No hay contenido en la respuesta de Gemini: ${response.body}',
          );
        }

        final content = candidate['content'];

        String? text;

        if (content['parts'] != null && content['parts'].isNotEmpty) {
          text = content['parts'][0]['text'];
        } else if (content['text'] != null) {
          text = content['text'];
        }

        if (text == null || text.isEmpty) {
          throw Exception(
            'No se encontró texto en la respuesta de Gemini: ${response.body}',
          );
        }

        return text;
      } else {
        throw Exception('Error: ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error al comunicarse con Gemini: $e');
    }
  }
}
