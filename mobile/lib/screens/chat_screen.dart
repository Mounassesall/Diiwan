import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';

import '../widgets/table_widget.dart';
import '../widgets/chart_widget.dart';
import 'map_screen.dart';
import '../theme.dart';

/// Écran principal de dialogue avec l'API Diiwan.
///
/// Affiche un historique de conversation sous forme de bulles (utilisateur à
/// droite, réponse de l'agent à gauche), un champ de saisie, un bouton Envoyer,
/// un indicateur de chargement pendant l'appel réseau, et un bandeau
/// « Données pédagogiques fictives » quand metadata.fictitious est true.
class DiiwanChatScreen extends StatefulWidget {
  final String? prefilledQuestion;

  const DiiwanChatScreen({super.key, this.prefilledQuestion});

  @override
  State<DiiwanChatScreen> createState() => _DiiwanChatScreenState();
}

class _DiiwanChatScreenState extends State<DiiwanChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.prefilledQuestion != null && widget.prefilledQuestion!.isNotEmpty) {
      _controller.text = widget.prefilledQuestion!;
    }
  }

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
      if (lastMsg != null && !lastMsg.isUser && (lastMsg.content.startsWith('Erreur') || lastMsg.content.startsWith('Le serveur') || lastMsg.content.startsWith('Requête'))) {
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

  void _showHelpDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.help_outline, color: DiiwanTheme.primary, size: 26),
                    const SizedBox(width: 10),
                    Text('Comment utiliser Diiwan ?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        )),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Posez vos questions en français naturel sur les régions du Sénégal.',
                    style: TextStyle(color: DiiwanTheme.textSecondary(isDark), fontSize: 13)),
                const SizedBox(height: 20),

                // Indicateurs
                Text('📊 Indicateurs disponibles',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: DiiwanTheme.primary,
                      fontSize: 14,
                    )),
                const SizedBox(height: 8),
                ...const [
                  '• Population',
                  '• Taux de chômage (%)',
                  '• Taux de pauvreté (%)',
                  "• Taux d'alphabétisation (%)",
                  "• Taux d'urbanisation (%)",
                  '• Taux de scolarisation (%)',
                  "• Accès à Internet (%)",
                  '• Centres de santé (nb)',
                  '• Production céréalière (tonnes)',
                ].map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(s,
                          style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155))),
                    )),

                const SizedBox(height: 20),

                // Exemples
                Text('💡 Exemples de questions',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: DiiwanTheme.primary,
                      fontSize: 14,
                    )),
                const SizedBox(height: 8),
                ...const [
                  '"Quelle est la population de Dakar en 2024 ?"',
                  '"Compare le chômage à Thiès et Saint-Louis."',
                  '"Montre l\'évolution de l\'accès internet à Matam de 2020 à 2024."',
                  '"Quelles sont les 5 régions les plus peuplées ?"',
                  '"Population totale du Sénégal en 2024 ?"',
                ].map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(s,
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          )),
                    )),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DiiwanTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Compris !'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            children: [
              const TextSpan(text: 'Diiwan  ', style: TextStyle(color: DiiwanTheme.primary, fontWeight: FontWeight.bold, fontSize: 22, fontFamily: 'Inter')),
              TextSpan(text: 'Sénégal Stats AI', style: TextStyle(color: DiiwanTheme.textSecondary(isDark), fontSize: 12, fontWeight: FontWeight.w500, fontFamily: 'Inter')),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Provider.of<ChatProvider>(context).themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
              color: DiiwanTheme.textSecondary(isDark),
            ),
            tooltip: 'Changer le thème',
            onPressed: () {
              Provider.of<ChatProvider>(context, listen: false).toggleTheme();
            },
          ),
          IconButton(
            icon: Icon(Icons.map, color: DiiwanTheme.textSecondary(isDark)),
            tooltip: 'Carte choroplèthe',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MapScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.help_outline, color: DiiwanTheme.textSecondary(isDark)),
            tooltip: 'Aide',
            onPressed: () => _showHelpDialog(context, isDark),
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chat, child) {
          final messages = chat.messages.reversed.toList();
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
            children: [



              // Liste des messages (historique de conversation)
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: messages.length + (messages.length <= 1 ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (messages.length <= 1 && index == 1) {
                      // Suggestions de questions après le message de bienvenue (index 1 en reverse)
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            'Quelle est la population de Dakar en 2024 ?',
                            'Compare le chômage à Dakar, Thiès et Saint-Louis en 2024',
                            'Top 5 régions avec le meilleur accès internet en 2024',
                          ].map((q) => ActionChip(
                            label: Text(q, style: TextStyle(fontSize: 12, color: DiiwanTheme.textPrimary(isDark))),
                            backgroundColor: DiiwanTheme.surface(isDark),
                            side: BorderSide(color: DiiwanTheme.border(isDark)),
                            onPressed: () {
                              _controller.text = q;
                              _send(); // Envoyer immédiatement
                            },
                          )).toList(),
                        ),
                      );
                    }

                    // Ajuster l'index si les suggestions sont affichées
                    final msgIndex = (messages.length <= 1 && index > 0) ? index - 1 : index;
                    final msg = messages[msgIndex];
                    final isUser = msg.isUser;
                    final hasTable = msg.response != null && msg.response!.table.isNotEmpty;
                    final hasChart = msg.response != null && msg.response!.chart != null;

                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isUser)
                            Padding(
                              padding: const EdgeInsets.only(left: 16, bottom: 6),
                              child: CircleAvatar(
                                radius: 14,
                                backgroundColor: DiiwanTheme.surface(isDark),
                                child: const Icon(Icons.smart_toy, size: 16, color: DiiwanTheme.primary),
                              ),
                            ),
                          Flexible(
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.75,
                              ),
                              margin: EdgeInsets.only(
                                left: isUser ? 16 : 8,
                                right: isUser ? 16 : 16,
                                top: 6,
                                bottom: 6,
                              ),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isUser ? DiiwanTheme.userBubbleBg(isDark) : DiiwanTheme.botBubbleBg(isDark),
                                border: isUser ? null : Border.all(color: DiiwanTheme.border(isDark)),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(18),
                                  topRight: const Radius.circular(18),
                                  bottomLeft: isUser ? const Radius.circular(18) : Radius.zero,
                                  bottomRight: isUser ? Radius.zero : const Radius.circular(18),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msg.content,
                                    style: TextStyle(
                                      color: isUser ? Colors.white : DiiwanTheme.textPrimary(isDark),
                                      fontSize: 15,
                                      height: 1.4,
                                    ),
                                  ),
                                  if (hasTable)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: DiiwanTable(tableRows: msg.response!.table),
                                    ),
                                  if (hasChart)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: DiiwanChart(chartData: msg.response!.chart!),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Indicateur de chargement
              if (chat.isLoading) 
                const LinearProgressIndicator(
                  backgroundColor: Color(0xFF1E293B),
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                ),

              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  border: Border(top: BorderSide(color: DiiwanTheme.border(isDark))),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            style: TextStyle(color: DiiwanTheme.textPrimary(isDark)),
                            decoration: InputDecoration(
                              hintText: 'Posez votre question…',
                              hintStyle: TextStyle(color: DiiwanTheme.textSecondary(isDark)),
                              filled: true,
                              fillColor: DiiwanTheme.surface(isDark),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(color: DiiwanTheme.primary, width: 1.5),
                              ),
                            ),
                            onSubmitted: (_) => _send(),
                            textInputAction: TextInputAction.send,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.send, color: Colors.white),
                            onPressed: _send,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          )));
        },
      ),
    );
  }
}
