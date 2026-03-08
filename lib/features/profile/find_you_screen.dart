import 'package:flutter/material.dart';
import 'services/mentor_service.dart';

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.isLoading = false,
  });

  final String text;
  final bool isUser;
  final bool isLoading;
}

class FindYouScreen extends StatefulWidget {
  const FindYouScreen({super.key});

  @override
  State<FindYouScreen> createState() => _FindYouScreenState();
}

class _FindYouScreenState extends State<FindYouScreen> {
  final MentorService _mentorService = MentorService();
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = const [
    _ChatMessage(
      text:
          'Hi, I am your mentor. You can talk to me about stress, emotions, motivation, or anything on your mind.',
      isUser: false,
    ),
  ].toList();
  bool _isLoading = false;

  @override
  void dispose() {
    _queryController.dispose();
    _scrollController.dispose();
    _mentorService.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _askMentor() async {
    final userQuery = _queryController.text.trim();
    if (userQuery.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please share what\'s on your mind'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _messages.add(_ChatMessage(text: userQuery, isUser: true));
      _messages.add(
        const _ChatMessage(text: 'Thinking...', isUser: false, isLoading: true),
      );
    });
    _queryController.clear();
    _scrollToBottom();

    try {
      final response = await _mentorService.getPersonalizedAdvice(userQuery);

      setState(() {
        _isLoading = false;
        _messages.removeLast();
        _messages.add(_ChatMessage(text: response, isUser: false));
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _messages.removeLast();
        _messages.add(
          _ChatMessage(
            text: 'Error: ${e.toString()}',
            isUser: false,
          ),
        );
      });
      _scrollToBottom();
      print('Error: $e');
    }
  }

  Widget _buildMessageBubble(_ChatMessage message) {
    final bubbleColor = message.isUser ? const Color(0xFF00D4A4) : Colors.white;
    final textColor = message.isUser ? Colors.white : const Color(0xFF1F2937);
    final alignment =
        message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(message.isUser ? 20 : 6),
      bottomRight: Radius.circular(message.isUser ? 6 : 20),
    );

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Text(
            message.isUser ? 'You' : 'Mentor',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: message.isUser
                  ? const Color(0xFF0F766E)
                  : const Color(0xFF6B7280),
            ),
          ),
        ),
        Container(
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: message.isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Color(0xFF00D4A4),
                  ),
                )
              : Text(
                  message.text,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    height: 1.45,
                  ),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        title: const Text('Find You'),
        backgroundColor: const Color(0xFF00D4A4),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                itemCount: _messages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return Align(
                    alignment: message.isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: _buildMessageBubble(message),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _queryController,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: 'How are you feeling? What\'s on your mind?',
                        filled: true,
                        fillColor: const Color(0xFFF3F6FB),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _askMentor,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D4A4),
                        foregroundColor: Colors.white,
                        shape: const CircleBorder(),
                        padding: EdgeInsets.zero,
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.arrow_upward_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
