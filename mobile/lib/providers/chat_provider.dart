import 'dart:convert';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/diiwan_response.dart';

class ChatMessage {
  final String content;
  final bool isUser;
  final DiiwanResponse? response;
  ChatMessage({required this.content, required this.isUser, this.response});
}

class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [
    ChatMessage(
      content: 'Bonjour ! Je suis Diiwan, votre assistant sur les données régionales du Sénégal. Posez-moi une question ou ouvrez la carte en haut à droite !',
      isUser: false,
    )
  ];
  bool _isLoading = false;
  late final String _baseUrl;
  DiiwanResponse? _lastResponse;

  ThemeMode _themeMode = ThemeMode.dark;
  
  ChatProvider() {
    const envUrl = String.fromEnvironment('BASE_URL', defaultValue: 'https://diiwan-backend.onrender.com');
    if (envUrl.isNotEmpty) {
      _baseUrl = envUrl;
    } else if (!kIsWeb && Platform.isAndroid) {
      _baseUrl = 'http://10.0.2.2:8000';
    } else {
      _baseUrl = 'http://localhost:8000';
    }
  }

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  DiiwanResponse? get lastResponse => _lastResponse;
  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void _addMessage(String content, bool isUser, {DiiwanResponse? response}) {
    _messages.add(ChatMessage(content: content, isUser: isUser, response: response));
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
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final diiwanResponse = DiiwanResponse.fromJson(json);
        _addMessage(diiwanResponse.answer, false, response: diiwanResponse);
        _lastResponse = diiwanResponse;
      } else if (response.statusCode == 400) {
        _addMessage('Requête invalide (400)', false);
      } else {
        _addMessage('Erreur serveur (${response.statusCode})', false);
      }
    } on TimeoutException catch (_) {
      _addMessage('❗ Le serveur ne répond pas, réessayez', false);
    } catch (e) {
      _addMessage('❗ Erreur réseau : $e', false);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

}
