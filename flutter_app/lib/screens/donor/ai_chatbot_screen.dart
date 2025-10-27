import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/patient.dart';
import '../../utils/formatters.dart';
import '../../services/firestore_service.dart';
import '../../services/api_service.dart';

/// ---------------- Suggested Replies Helper ----------------
List<String> _defaultSuggestedReplies(Patient? patient) {
  switch (patient?.priorityLevel.toLowerCase()) {
    case 'critical':
      return ['Donate Now', 'Urgent Support', 'Share Profile'];
    case 'high':
      return ['Donate Now', 'Send Encouragement', 'Share Profile'];
    case 'general':
      return ['Donate Now', 'Like Profile', 'Share Profile'];
    default:
      return ['Donate Now', 'Support Patient'];
  }
}

/// ---------------- Chat Message Model ----------------
class ChatMessage {
  final String message;
  final bool isUser;

  ChatMessage({required this.message, required this.isUser});
}

/// ---------------- AI ChatBot Screen ----------------
class AiChatbotScreen extends StatefulWidget {
  final Patient? patient;

  const AiChatbotScreen({Key? key, this.patient}) : super(key: key);

  @override
  State<AiChatbotScreen> createState() => _AiChatbotScreenState();
}

class _AiChatbotScreenState extends State<AiChatbotScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _isTyping = false;
  String? _conversationId;
  List<String> _suggestions = [];

  Future<void> _sendMessage([String? text]) async {
    final messageText = text ?? _controller.text.trim();
    if (messageText.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(message: messageText, isUser: true));
      _isTyping = true;
      _controller.clear();
    });

    try {
      final res = await _api.chatWithAI(
        message: messageText,
        conversationId: _conversationId,
      );

      if (!mounted) return;
      final botMessage = (res['message'] ?? '').toString();
      final newConversationId = res['conversationId']?.toString();
      final suggestionsRaw = res['suggestions'];
      final suggestions = suggestionsRaw is List
          ? suggestionsRaw.map((e) => e.toString()).toList()
          : <String>[];

      setState(() {
        _messages.add(ChatMessage(message: botMessage, isUser: false));
        _isTyping = false;
        _conversationId = newConversationId ?? _conversationId;
        _suggestions = suggestions;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(
            message:
                'Sorry, I\'m having trouble responding right now. Please try again later.',
            isUser: false));
        _isTyping = false;
      });
      _scrollToBottom();
      return;
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Color _getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'general':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;
    final suggestedReplies = _suggestions.isNotEmpty
        ? _suggestions
        : _defaultSuggestedReplies(patient);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _getPriorityColor(patient?.priorityLevel),
        title: Text(
          patient != null
              ? '${patient.publicAlias} Chat (${patient.priorityLevel.toUpperCase()})'
              : 'CareConnect AI Chatbot',
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isTyping && index == _messages.length) {
                  return Row(
                    children: const [
                      SizedBox(width: 8),
                      CircularProgressIndicator(strokeWidth: 2),
                      SizedBox(width: 8),
                      Text('Bot is typing...'),
                    ],
                  );
                }
                final msg = _messages[index];
                return Align(
                  alignment:
                      msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: msg.isUser ? Colors.blue[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg.message,
                      style: TextStyle(
                        color: msg.isUser ? Colors.blue[900] : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Suggested Quick Replies
          if (!_isTyping && suggestedReplies.isNotEmpty)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final reply = suggestedReplies[index];
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getPriorityColor(patient?.priorityLevel),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () => _sendMessage(reply),
                    child: Text(reply),
                  );
                },
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemCount: suggestedReplies.length,
              ),
            ),

          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: () => _sendMessage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
