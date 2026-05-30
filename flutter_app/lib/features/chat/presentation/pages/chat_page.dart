import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/supabase_client.dart';

class ChatDetailPage extends ConsumerStatefulWidget {
  final String id;
  const ChatDetailPage({super.key, required this.id});
  @override
  ConsumerState<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends ConsumerState<ChatDetailPage> {
  final _msgCtrl    = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  RealtimeChannel? _channel;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _subscribeToMessages();
  }

  Future<void> _loadMessages() async {
    final svc  = ref.read(supabaseServiceProvider);
    final msgs = await svc.fetchMessages(widget.id);
    if (mounted) setState(() { _messages = msgs; _loading = false; });
    _scrollToBottom();
  }

  void _subscribeToMessages() {
    final svc = ref.read(supabaseServiceProvider);
    _channel  = svc.subscribeToMessages(widget.id, (msg) {
      if (mounted) setState(() => _messages.add(msg));
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _sendMessage() async {
    final body = _msgCtrl.text.trim();
    if (body.isEmpty) return;
    _msgCtrl.clear();

    final client = ref.read(supabaseClientProvider);
    final user   = client.auth.currentUser;
    if (user == null) return;

    await client.from('messages').insert({
      'conversation_id': widget.id,
      'sender_id':       user.id,
      'body':            body,
    });
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.read(supabaseClientProvider).auth.currentUser?.id;
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [
          CircleAvatar(backgroundColor: AppTheme.goldPrimary, child: Text('P', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700))),
          SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('ProBrake Co.', style: TextStyle(fontSize: 14)),
            Text('● Online · Verified', style: TextStyle(fontSize: 10, color: AppTheme.colorGreen)),
          ]),
        ]),
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller:  _scrollCtrl,
                    padding:     const EdgeInsets.all(16),
                    itemCount:   _messages.length,
                    itemBuilder: (ctx, i) {
                      final msg    = _messages[i];
                      final isMe   = msg['sender_id'] == userId;
                      final body   = msg['body'] as String? ?? '';
                      final time   = (msg['created_at'] as String?)?.substring(11, 16) ?? '';
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin:  const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(ctx).size.width * 0.7),
                          decoration: BoxDecoration(
                            gradient: isMe ? AppTheme.goldGradient : null,
                            color:    isMe ? null : AppTheme.bgCard,
                            borderRadius: BorderRadius.circular(14),
                            border: isMe ? null : Border.all(color: AppTheme.borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(body, style: TextStyle(color: isMe ? Colors.black : AppTheme.textPrimary, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text(time, style: TextStyle(fontSize: 9, color: isMe ? Colors.black54 : AppTheme.textDim)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppTheme.borderColor))),
            child: Row(children: [
              IconButton(icon: const Icon(Icons.attach_file, color: AppTheme.textMuted), onPressed: () {}),
              Expanded(
                child: TextField(
                  controller: _msgCtrl,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: const InputDecoration(hintText: 'Type a message...', contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: _sendMessage, child: const Text('Send')),
            ]),
          ),
        ],
      ),
    );
  }
}
