import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/chat_provider.dart';
import 'screens/chat_screen.dart';

import 'theme.dart';

import 'dart:ui';

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

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}

class DiiwanApp extends StatelessWidget {
  const DiiwanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chat, child) {
        return MaterialApp(
          title: 'Diiwan',
          debugShowCheckedModeBanner: false,
          scrollBehavior: MyCustomScrollBehavior(),
          theme: DiiwanTheme.lightTheme,
          darkTheme: DiiwanTheme.darkTheme,
          themeMode: chat.themeMode,
          home: const DiiwanChatScreen(),
        );
      },
    );
  }
}
