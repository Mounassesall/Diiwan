// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:provider/provider.dart';
import 'package:diiwam_mobile/providers/chat_provider.dart';
import 'package:diiwam_mobile/models/diiwan_response.dart';
import 'package:diiwam_mobile/screens/chat_screen.dart';
import 'package:diiwam_mobile/main.dart';

class MockChatProvider extends ChatProvider {
  final List<ChatMessage> _mockMessages = [];
  bool _mockIsLoading = false;
  DiiwanResponse? _mockLastResponse;

  @override
  List<ChatMessage> get messages => _mockMessages;

  @override
  bool get isLoading => _mockIsLoading;

  @override
  DiiwanResponse? get lastResponse => _mockLastResponse;

  @override
  Future<void> sendQuestion(String question) async {
    // Override for tests
  }

  void injectState({
    required List<ChatMessage> msgs,
    bool loading = false,
    DiiwanResponse? response,
  }) {
    _mockMessages.clear();
    _mockMessages.addAll(msgs);
    _mockIsLoading = loading;
    _mockLastResponse = response;
    notifyListeners();
  }
}

void main() {
  testWidgets('App loads successfully (App root)', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ChatProvider()),
        ],
        child: const DiiwanApp(),
      ),
    );
    expect(find.text('Diiwan'), findsWidgets);
  });

  testWidgets('Affiche une reponse simple', (WidgetTester tester) async {
    final mockProvider = MockChatProvider();
    
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<ChatProvider>.value(
          value: mockProvider,
          child: const DiiwanChatScreen(),
        ),
      ),
    );

    mockProvider.injectState(
      msgs: [
        ChatMessage(content: 'Combien d\'habitants a Dakar en 2024 ?', isUser: true),
        ChatMessage(content: 'En 2024, la population de Dakar est estimee a 4 millions.', isUser: false),
      ],
      response: null,
    );
    await tester.pumpAndSettle();

    expect(find.text('En 2024, la population de Dakar est estimee a 4 millions.'), findsOneWidget);
  });

  testWidgets('Affiche le bandeau donnees fictives conditionnel', (WidgetTester tester) async {
    final mockProvider = MockChatProvider();
    
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<ChatProvider>.value(
          value: mockProvider,
          child: const DiiwanChatScreen(),
        ),
      ),
    );

    // Initial state: no banner
    expect(find.text('Données pédagogiques fictives'), findsNothing);

    mockProvider.injectState(
      msgs: [],
      response: DiiwanResponse(
        answer: "Reponse fictive",
        table: [],
        metadata: Metadata(fictitious: true, rowsUsed: 1),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Données pédagogiques fictives'), findsOneWidget);
  });

  testWidgets('Gestion d une erreur reseau et affichage d erreur', (WidgetTester tester) async {
    final mockProvider = MockChatProvider();
    
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<ChatProvider>.value(
          value: mockProvider,
          child: const DiiwanChatScreen(),
        ),
      ),
    );

    // Simulate clicking send which triggers snackbar based on mock logic.
    // Wait, the chat screen shows a snackbar IF the *new* last message is an error.
    // We can simulate the user sending a message, which updates the mock and then shows snackbar.
    // To do this properly without network, we can just inject an error message in the chat history.
    mockProvider.injectState(
      msgs: [
        ChatMessage(content: '❗ Erreur serveur (500)', isUser: false),
      ],
    );
    await tester.pumpAndSettle();

    // The chat history itself displays the error text.
    expect(find.text('❗ Erreur serveur (500)'), findsOneWidget);
  });

  testWidgets('Gestion d une erreur de Timeout et affichage d erreur', (WidgetTester tester) async {
    final mockProvider = MockChatProvider();
    
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<ChatProvider>.value(
          value: mockProvider,
          child: const DiiwanChatScreen(),
        ),
      ),
    );

    mockProvider.injectState(
      msgs: [
        ChatMessage(content: '❗ Le serveur ne répond pas, réessayez', isUser: false),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('❗ Le serveur ne répond pas, réessayez'), findsOneWidget);
  });
}
