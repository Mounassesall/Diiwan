import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/chat_provider.dart';
import 'screens/chat_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: const DiiwanApp(),
    ),
  );
}

class DiiwanApp extends StatelessWidget {
  const DiiwanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diiwan',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const DiiwanChatScreen(),
    );
  }
}
