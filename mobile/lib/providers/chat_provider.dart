import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/diiwan_response.dart';

class ChatMessage {
  final String content;
  final bool isUser;
  ChatMessage({required this.content, required this.isUser});
}

class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  final String _baseUrl = const String.fromEnvironment('BASE_URL', defaultValue: 'http://localhost:8000');

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;

  void _addMessage(String text, bool user) {
    _messages.add(ChatMessage(content: text, isUser: user));
    notifyListeners();
  }

  Future<void> sendQuestion(String question) async {
    _addMessage(question, true);
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/question/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'question': question}),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final diiwanResponse = DiiwanResponse.fromJson(json);
        final buffer = StringBuffer();
        if (diiwanResponse.metadata.fictitious) {
          buffer.writeln('💡 Données pédagogiques fictives');
        }
        buffer.writeln(diiwanResponse.answer);
        _addMessage(buffer.toString(), false);
        _lastResponse = diiwanResponse;
      } else if (response.statusCode == 400) {
        _addMessage('❗ Requête invalide (400)', false);
      } else {
        _addMessage('❗ Erreur serveur (${response.statusCode})', false);
      }
    } catch (e) {
      _addMessage('❗ Erreur réseau : $e', false);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  DiiwanResponse? _lastResponse;
  DiiwanResponse? get lastResponse => _lastResponse;
}
