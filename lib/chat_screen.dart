import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'constants.dart';
import 'models.dart';
import 'widgets.dart';

String chatIdFor(String a, String b) {
  final ids = [a, b]..sort();
  return ids.join('_');
}

Future<void> sendChatMessage(String chatId, String text) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return;

  final supabase = Supabase.instance.client;
  final now = DateTime.now().toIso8601String();

  await supabase.from('messages').insert({
    'chat_id': chatId,
    'sender_id': user.id,
    'text': text,
  });

  await supabase.from('chats').update({
    'last_message': text,
    'last_time': now,
  }).eq('id', chatId);
}

Future<void> startChat(
  BuildContext context, {
  required String otherUid,
  required String otherName,
  String? firstMessage,
}) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return;
  
  final supabase = Supabase.instance.client;
  
  String myName = 'User';
  try {
    final profile = await supabase.from('profiles').select('name').eq('id', user.id).maybeSingle();
    myName = profile?['name']?.toString() ?? (user.email ?? 'User').split('@').first;
  } catch (_) {
    myName = (user.email ?? 'User').split('@').first;
  }
                 
  final chatId = chatIdFor(user.id, otherUid);
  final navigator = Navigator.of(context);

  final existingChat = await supabase.from('chats').select().eq('id', chatId).maybeSingle();
  
  if (existingChat == null) {
    await supabase.from('chats').insert({
      'id': chatId,
      'participants': [user.id, otherUid],
      'names': {user.id: myName, otherUid: otherName},
    });
  }

  if (firstMessage != null) await sendChatMessage(chatId, firstMessage);

  navigator.push(MaterialPageRoute(
      builder: (_) => ChatScreen(chatId: chatId, otherName: otherName)));
}

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherName;
  const ChatScreen({super.key, required this.chatId, required this.otherName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final controller = TextEditingController();
  late final Stream<List<Map<String, dynamic>>> _stream;
  final String myId = Supabase.instance.client.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _stream = Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', widget.chatId)
        .order('created_at', ascending: false);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    controller.clear();
    FocusScope.of(context).unfocus();
    try {
      await sendChatMessage(widget.chatId, text);
    } catch (e) {
      if (mounted) showMsg(context, 'Message not sent: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              PageHeader(title: widget.otherName),
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _stream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return EmptyState(
                        icon: Icons.error_outline,
                        title: 'Error loading messages',
                        subtitle: '${snapshot.error}',
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const LoadingView();
                    }
                    
                    final messages = (snapshot.data ?? [])
                        .map((d) => ChatMessage.fromMap(d))
                        .toList();
                        
                    if (messages.isEmpty) {
                      return const EmptyState(
                        icon: Icons.chat_bubble_outline,
                        title: 'No messages yet',
                        subtitle: 'Say hello 👋',
                      );
                    }
                    
                    return ListView.builder(
                      reverse: true,
                      itemCount: messages.length,
                      itemBuilder: (_, i) {
                        final m = messages[i];
                        final me = m.senderId == myId;
                        return Align(
                          alignment: me ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                            constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.72),
                            color: me ? kTeal : Colors.white,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(m.text,
                                    style: TextStyle(
                                        color: me ? Colors.white : kNavy,
                                        fontSize: 15)),
                                const SizedBox(height: 4),
                                Text(formatTime(m.createdAt),
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: me ? Colors.white70 : kGrey)),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: Container(
                    height: 54,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    color: Colors.white,
                    child: TextField(
                      controller: controller,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(color: kGrey)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                      height: 54,
                      width: 54,
                      color: kTeal,
                      child: const Icon(Icons.send, color: Colors.white)),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}