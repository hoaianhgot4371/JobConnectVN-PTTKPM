import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/api/api_client.dart';

class AIChatScreen extends StatefulWidget {
  final Map<String, dynamic>? initialContext;
  const AIChatScreen({super.key, this.initialContext});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<Map<String, dynamic>> _messages = [
    {
      'role': 'ai',
      'content':
          'Xin chào! Tôi là trợ lý AI của JobConnect. Tôi có thể giúp gì cho bạn hôm nay? (Review công việc, tìm thông tin công ty...)'
    }
  ];
  bool _isLoading = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _msgCtrl.clear();
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final res = await ApiClient().dio.post('/ai/chat', data: {
        'prompt': text,
        'context': widget.initialContext ?? {},
      });

      final answer = (res.data['answer'] as String?)?.trim();
      setState(() {
        _messages.add({
          'role': 'ai',
          'content': answer == null || answer.isEmpty
              ? 'AI chua co phan hoi phu hop. Ban thu hoi lai ro hon nhe.'
              : answer,
        });
        _isLoading = false;
      });
      _scrollToBottom();
    } on DioException catch (e) {
      String errorMsg = ApiClient.parseError(e);
      setState(() {
        _messages.add({'role': 'ai', 'content': 'Lỗi: $errorMsg'});
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'ai',
          'content': 'Xin lỗi, tôi đang gặp chút sự cố. Vui lòng thử lại sau!'
        });
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text('Trợ lý AI',
                style: GoogleFonts.sora(
                    fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final m = _messages[index];
                final isAI = m['role'] == 'ai';
                return _buildBubble(m['content'], isAI);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildBubble(String text, bool isAI) {
    return Align(
      alignment: isAI ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isAI ? AppColors.bgPurpleLight : AppColors.primary,
          borderRadius: BorderRadius.circular(12).copyWith(
            bottomLeft:
                isAI ? const Radius.circular(0) : const Radius.circular(12),
            bottomRight:
                !isAI ? const Radius.circular(0) : const Radius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: isAI ? AppColors.textPrimary : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _msgCtrl,
                decoration: InputDecoration(
                  hintText: 'Hỏi AI bất cứ điều gì...',
                  hintStyle: GoogleFonts.dmSans(fontSize: 14),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none),
                  filled: true,
                  fillColor: AppColors.bgPurpleLight.withOpacity(0.5),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send),
              style: IconButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
