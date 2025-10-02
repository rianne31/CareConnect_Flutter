import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/api_service.dart';

class AIChatbotScreen extends StatefulWidget {
  const AIChatbotScreen({Key? key}) : super(key: key);

  @override
  State<AIChatbotScreen> createState() => _AIChatbotScreenState();
}

class _AIChatbotScreenState extends State<AIChatbotScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _conversationId;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(ChatMessage(
        text: "Hello! I'm CareConnect AI, your personal assistant for supporting children battling cancer. I can help you:\n\n• Find patients who need support\n• Learn about our impact\n• Get donation recommendations\n• Answer questions about our foundation\n\nHow can I assist you today?",
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _messages.add(ChatMessage(
        text: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });

    _scrollToBottom();

    try {
      final user = FirebaseAuth.instance.currentUser;
      
      final response = await _apiService.chatWithAI(
        message: userMessage,
        conversationId: _conversationId,
      );

      if (!mounted) return;

      setState(() {
        _messages.add(ChatMessage(
          text: response['message'] ?? 'I apologize, but I encountered an error. Please try again.',
          isUser: false,
          timestamp: DateTime.now(),
          suggestions: response['suggestions'] != null 
              ? List<String>.from(response['suggestions']) 
              : null,
        ));
        _isTyping = false;
        
        // Store conversation ID for future messages
        _conversationId = response['conversationId'];
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _messages.add(ChatMessage(
          text: 'I apologize, but I encountered an error: ${e.toString()}',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isTyping = false;
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendSuggestion(String suggestion) {
    _messageController.text = suggestion;
    _sendMessage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.smart_toy),
            SizedBox(width: 8),
            Text('CareConnect AI'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _messages.clear();
                _addWelcomeMessage();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _MessageBubble(
                  message: message,
                  onSuggestionTap: _sendSuggestion,
                );
              },
            ),
          ),

          // Typing Indicator
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.blue[100],
                    child: const Icon(Icons.smart_toy, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _TypingDot(delay: 0),
                        const SizedBox(width: 4),
                        _TypingDot(delay: 200),
                        const SizedBox(width: 4),
                        _TypingDot(delay: 400),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FloatingActionButton(
                    onPressed: _isTyping ? null : _sendMessage,
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String>? suggestions;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.suggestions,
  });
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final Function(String) onSuggestionTap;

  const _MessageBubble({
    required this.message,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue[100],
              child: const Icon(Icons.smart_toy, size: 16),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser 
                  ? CrossAxisAlignment.end 
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: message.isUser 
                        ? Colors.blue 
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                if (message.suggestions != null && message.suggestions!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: message.suggestions!.map((suggestion) {
                      return ActionChip(
                        label: Text(suggestion),
                        onPressed: () => onSuggestionTap(suggestion),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue[100],
              child: const Icon(Icons.person, size: 16),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  final int delay;

  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.grey,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
