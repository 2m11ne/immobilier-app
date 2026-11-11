import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'constants.dart';
import 'models.dart';
import 'widgets.dart';

String chatIdFor(String a, String b) {
  final ids = [a, b]..sort();
  return ids.join('_');
}

Future<void> sendChatMessage(String chatId, String text) async {
  final me = FirebaseAuth.instance.currentUser!;
  final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);

  final message = ChatMessage(
      id: '', text: text, senderId: me.uid, createdAt: DateTime.now());
  await chatRef.collection('messages').add(message.toMap());
  await chatRef.set({
    'lastMessage': text,
    'lastTime': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}

Future<void> startChat(
  BuildContext context, {
  required String otherUid,
  required String otherName,
  String? firstMessage,
}) async {
  final me = FirebaseAuth.instance.currentUser!;
  final myName = (me.displayName != null && me.displayName!.isNotEmpty)
      ? me.displayName!
      : (me.email ?? 'User');
  final chatId = chatIdFor(me.uid, otherUid);
  final navigator = Navigator.of(context);

  await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
    'participants': [me.uid, otherUid],
    'names': {me.uid: myName, otherUid: otherName},
  }, SetOptions(merge: true));

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
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream;
  final String myId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _stream = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots();
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
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _stream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const EmptyState(
                        icon: Icons.error_outline,
                        title: 'Something went wrong',
                        subtitle: 'Could not load the messages.',
                      );
                    }
                    if (!snapshot.hasData) return const LoadingView();
                    final messages = snapshot.data!.docs
                        .map((d) => ChatMessage.fromMap(d.data(), d.id))
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
                          alignment:
                              me ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                            constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.72),
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
                                        color: me
                                            ? Colors.white70
                                            : kGrey)),
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