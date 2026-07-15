import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/diiwan_response.dart';
import '../widgets/table_widget.dart';
import '../widgets/chart_widget.dart';
import 'map_screen.dart';

/// Écran principal de dialogue avec l'API Diiwan.
///
/// Affiche un historique de conversation sous forme de bulles (utilisateur à
/// droite, réponse de l'agent à gauche), un champ de saisie, un bouton Envoyer,
/// un indicateur de chargement pendant l'appel réseau, et un bandeau
/// « Données pédagogiques fictives » quand metadata.fictitious est true.
class DiiwanChatScreen extends StatefulWidget {
  const DiiwanChatScreen({super.key});

  @override
  State<DiiwanChatScreen> createState() => _DiiwanChatScreenState();
}

class _DiiwanChatScreenState extends State<DiiwanChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final provider = Provider.of<ChatProvider>(context, listen: false);
    provider.sendQuestion(text).then((_) {
      // Afficher une erreur via SnackBar si la dernière réponse est une erreur
      final lastMsg = provider.messages.lastOrNull;
      if (lastMsg != null && !lastMsg.isUser && lastMsg.content.startsWith('❗')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(lastMsg.content),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      }
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Diiwan',
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          // Bouton pour ouvrir la carte choroplèthe
          IconButton(
            icon: const Icon(Icons.map),
            tooltip: 'Carte choroplèthe',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MapScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chat, child) {
          final messages = chat.messages.reversed.toList();
          final lastResponse = chat.lastResponse;
          return Column(
            children: [
              // Bandeau « Données pédagogiques fictives »
              if (lastResponse != null && lastResponse.metadata.fictitious)
                Container(
                  width: double.infinity,
                  color: Colors.amber.shade100,
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.orange),
                      SizedBox(width: 6),
                      Text(
                        'Données pédagogiques fictives',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange),
                      ),
                    ],
                  ),
                ),

              // Liste des messages (historique de conversation)
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isUser = msg.isUser;
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUser ? Colors.deepPurple.shade100 : Colors.grey.shade200,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(14),
                            topRight: const Radius.circular(14),
                            bottomLeft: isUser ? const Radius.circular(14) : Radius.zero,
                            bottomRight: isUser ? Radius.zero : const Radius.circular(14),
                          ),
                        ),
                        child: Text(
                          msg.content,
                          style: TextStyle(
                            color: isUser ? Colors.deepPurple.shade900 : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Tableau (si la dernière réponse contient des données tabulaires)
              if (lastResponse != null && lastResponse.table.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: DiiwanTable(tableRows: lastResponse.table),
                ),

              // Graphique (si la dernière réponse contient un chart)
              if (lastResponse != null && lastResponse.chart != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: DiiwanChart(chartData: lastResponse.chart!),
                ),

              // Indicateur de chargement
              if (chat.isLoading) const LinearProgressIndicator(),

              // Barre de saisie
              const Divider(height: 1),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: 'Posez votre question…',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          onSubmitted: (_) => _send(),
                          textInputAction: TextInputAction.send,
                        ),
                      ),
                      const SizedBox(width: 8),
                      FloatingActionButton.small(
                        onPressed: _send,
                        child: const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
