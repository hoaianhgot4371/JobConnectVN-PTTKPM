import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:jobconnect_vn/core/api/api_client.dart';
import 'package:jobconnect_vn/core/theme/app_theme.dart';
import 'package:jobconnect_vn/models/models.dart';
import 'package:jobconnect_vn/core/widgets/shared_widgets.dart';

class ChatListScreen extends StatefulWidget {
  final JobModel? shareJob;

  const ChatListScreen({super.key, this.shareJob});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<ChatConversation> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchConversations();
  }

  Future<void> _fetchConversations() async {
    try {
      final response = await ApiClient().get('/chat/conversations');
      if (!mounted) return;
      
      if (response.statusCode == 200) {
        setState(() {
          _conversations = (response.data as List)
              .map((c) => ChatConversation.fromJson(c))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải danh sách chat: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Trò chuyện', style: GoogleFonts.sora(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        elevation: 0.5,
        backgroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchConversations,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _conversations.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) => _buildConversationItem(_conversations[index]),
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.border),
          const SizedBox(height: 16),
          Text('Chưa có cuộc hội thoại nào', style: GoogleFonts.dmSans(color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildConversationItem(ChatConversation conv) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: AvatarCircle(
        initials: conv.otherUser.name.isNotEmpty ? conv.otherUser.name[0].toUpperCase() : '?',
        size: 50, bg: AppColors.bgPurpleLight,
      ),
      title: Text(conv.otherUser.name, style: GoogleFonts.sora(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Text(
        conv.lastMessage?.type == 'job_share' ? '[Đã chia sẻ một công việc]' : (conv.lastMessage?.text ?? 'Bắt đầu trò chuyện ngay'),
        maxLines: 1, overflow: TextOverflow.ellipsis,
        style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary),
      ),
      trailing: Text(DateFormat('HH:mm').format(conv.updatedAt), style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textMuted)),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(
              conversationId: conv.id,
              otherUser: conv.otherUser,
              shareJob: widget.shareJob,
            ),
          ),
        ).then((_) {
          if (mounted) _fetchConversations();
        });
      },
    );
  }
}

class ChatDetailScreen extends StatefulWidget {
  final int? conversationId;
  final ChatUser otherUser;
  final JobModel? shareJob;

  const ChatDetailScreen({super.key, this.conversationId, required this.otherUser, this.shareJob});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  int? _activeConvId;

  @override
  void initState() {
    super.initState();
    _activeConvId = widget.conversationId;
    _fetchMessages();

    if (widget.shareJob != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _sendJobShare());
    }
  }

  Future<void> _fetchMessages() async {
    try {
      final String url = (_activeConvId != null && _activeConvId != 0)
          ? '/chat/messages/$_activeConvId'
          : '/chat/messages/null?otherUserId=${widget.otherUser.id}';

      debugPrint('Fetching messages from: $url');
      final res = await ApiClient().get(url);
      
      if (!mounted) return;

      if (res.statusCode == 200) {
        final List data = res.data;
        setState(() {
          _messages = data.map((m) => ChatMessage.fromJson(m)).toList();
          _isLoading = false;
          if (_messages.isNotEmpty && (_activeConvId == null || _activeConvId == 0)) {
            _activeConvId = _messages.first.conversationId;
          }
        });
        
        Future.delayed(const Duration(milliseconds: 100), () {
          _scrollToBottom();
        });
      }
    } catch (e) { 
      debugPrint('Lỗi khi tải tin nhắn: $e');
      if (mounted) setState(() => _isLoading = false); 
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    final tempMsg = ChatMessage(
      id: -1,
      conversationId: _activeConvId ?? 0,
      senderId: 0,
      messageText: text,
      messageType: 'text',
      isMe: true,
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages.add(tempMsg);
    });
    _scrollToBottom();

    try {
      final res = await ApiClient().post('/chat/send', data: {
        'conversationId': _activeConvId,
        'otherUserId': widget.otherUser.id,
        'message': text,
      });
      if (res.statusCode == 200 && mounted) {
        final msg = ChatMessage.fromJson(res.data);
        setState(() {
          int index = _messages.indexOf(tempMsg);
          if (index != -1) {
            _messages[index] = msg;
          }
          _activeConvId = msg.conversationId;
        });
      }
    } catch (e) {
      debugPrint('Lỗi gửi tin nhắn: $e');
      if (mounted) {
        setState(() {
          _messages.remove(tempMsg);
        });
      }
    }
  }

  Future<void> _sendJobShare() async {
    if (widget.shareJob == null) return;
    try {
      final res = await ApiClient().post('/chat/send', data: {
        'conversationId': _activeConvId,
        'otherUserId': widget.otherUser.id,
        'message': 'Chia sẻ công việc: ${widget.shareJob!.title}',
        'type': 'job_share',
        'jobId': widget.shareJob!.id,
      });
      if (res.statusCode == 200 && mounted) {
        final msg = ChatMessage.fromJson(res.data);
        setState(() { 
          _messages.add(msg); 
          _activeConvId = msg.conversationId; 
        });
        _scrollToBottom();
      }
    } catch (e) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        title: Text(widget.otherUser.name, style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : _messages.isEmpty 
                ? _buildNoMessages()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (ctx, idx) => _buildBubble(_messages[idx]),
                  ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildNoMessages() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.textMuted.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text('Chưa có tin nhắn nào.\nHãy bắt đầu cuộc trò chuyện!', 
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildBubble(ChatMessage msg) {
    final isMe = msg.isMe;
    final isPending = msg.id == -1;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? (isPending ? AppColors.primary.withOpacity(0.7) : AppColors.primary) : Colors.white,
          borderRadius: BorderRadius.circular(12).copyWith(
            bottomRight: isMe ? Radius.zero : const Radius.circular(12),
            bottomLeft: !isMe ? Radius.zero : const Radius.circular(12),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              msg.messageText ?? '',
              style: GoogleFonts.dmSans(color: isMe ? Colors.white : AppColors.textPrimary, fontSize: 14),
            ),
            if (isMe) ...[
              const SizedBox(height: 2),
              Icon(
                isPending ? Icons.access_time : Icons.done_all,
                size: 10,
                color: Colors.white70,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.bgPage,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Nhập tin nhắn...',
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
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
