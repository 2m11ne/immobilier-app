import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'chat_screen.dart';
import 'constants.dart';
import 'widgets.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                PageHeader(title: 'Messages', showBack: false),
                Expanded(
                  child: EmptyState(
                    icon: Icons.lock_outline,
                    title: 'Login required',
                    subtitle: 'Please create an account to view your messages.',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final String myId = user.id;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const PageHeader(title: 'Messages', showBack: false),
              const SizedBox(height: 20),
              Expanded(
                // We listen to the CHATS table to get the list of conversations
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: Supabase.instance.client
                      .from('chats')
                      .stream(primaryKey: ['id']),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return EmptyState(
                        icon: Icons.error_outline,
                        title: 'Something went wrong',
                        subtitle: '${snapshot.error}',
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const LoadingView();
                    }

                    final allChats = snapshot.data ?? [];
                    
                    // Filter chats where I am a participant
                    final myChats = allChats.where((d) {
                      final participants = List<String>.from(d['participants'] ?? []);
                      return participants.contains(myId);
                    }).toList();

                    // Sort by last_time
                    myChats.sort((a, b) {
                      final timeA = a['last_time'] != null ? DateTime.tryParse(a['last_time']) ?? DateTime.now() : DateTime.now();
                      final timeB = b['last_time'] != null ? DateTime.tryParse(b['last_time']) ?? DateTime.now() : DateTime.now();
                      return timeB.compareTo(timeA);
                    });

                    if (myChats.isEmpty) {
                      return const EmptyState(
                        icon: Icons.chat_bubble_outline,
                        title: 'No conversations yet',
                        subtitle: 'Open a property and tap "Rent Now" to contact the owner.',
                      );
                    }

                    return ListView.separated(
                      itemCount: myChats.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final data = myChats[i];
                        final participants = List<String>.from(data['participants'] ?? []);
                        
                        final otherId = participants.firstWhere(
                            (p) => p != myId,
                            orElse: () => myId);
                            
                        final names = Map<String, dynamic>.from(data['names'] ?? {});
                        final otherName = (names[otherId] ?? 'User').toString();
                        
                        final lastTimeStr = data['last_time'] as String?;
                        final lastTime = lastTimeStr != null 
                            ? DateTime.tryParse(lastTimeStr) ?? DateTime.now()
                            : DateTime.now();

                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                  chatId: data['id'], otherName: otherName),
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
                                    otherName.isEmpty ? '?' : otherName[0].toUpperCase(),
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
                                    Text((data['last_message'] ?? 'No messages yet') as String,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: kGrey)),
                                  ],
                                ),
                              ),
                              Text(formatTime(lastTime),
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