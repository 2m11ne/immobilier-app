import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'chat_screen.dart';
import 'constants.dart';
import 'widgets.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream;
  final String myId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _stream = FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: myId)
        .snapshots();
  }

  DateTime _time(Map<String, dynamic> data) =>
      (data['lastTime'] as Timestamp?)?.toDate() ?? DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const PageHeader(title: 'Messages', showBack: false),
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _stream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const EmptyState(
                        icon: Icons.error_outline,
                        title: 'Something went wrong',
                        subtitle: 'Could not load your conversations.',
                      );
                    }
                    if (!snapshot.hasData) return const LoadingView();

                    final docs = snapshot.data!.docs
                        .where((d) =>
                            ((d.data()['lastMessage'] ?? '') as String)
                                .isNotEmpty)
                        .toList()
                      ..sort((a, b) =>
                          _time(b.data()).compareTo(_time(a.data())));

                    if (docs.isEmpty) {
                      return const EmptyState(
                        icon: Icons.chat_bubble_outline,
                        title: 'No conversations yet',
                        subtitle:
                            'Open a property and tap "Rent Now" to contact the owner.',
                      );
                    }

                    return ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final doc = docs[i];
                        final data = doc.data();
                        final participants =
                            List<String>.from(data['participants'] ?? []);
                        final otherId = participants.firstWhere(
                            (p) => p != myId,
                            orElse: () => myId);
                        final names =
                            Map<String, dynamic>.from(data['names'] ?? {});
                        final otherName =
                            (names[otherId] ?? 'User') as String;

                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                  chatId: doc.id, otherName: otherName),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            color: Colors.white,
                            child: Row(children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: kTealLight,
                                child: Text(
                                    otherName.isEmpty
                                        ? '?'
                                        : otherName[0].toUpperCase(),
                                    style: const TextStyle(
                                        color: kTeal,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(otherName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: kNavy,
                                            fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Text((data['lastMessage'] ?? '') as String,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style:
                                            const TextStyle(color: kGrey)),
                                  ],
                                ),
                              ),
                              Text(formatTime(_time(data)),
                                  style: const TextStyle(
                                      color: kGrey, fontSize: 12)),
                            ]),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}