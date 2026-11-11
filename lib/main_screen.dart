import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'constants.dart';
import 'home_screen.dart';
import 'stats_screen.dart';
import 'messages_screen.dart';
import 'calculator_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int index = 0;

  // Note: We use a List instead of const List because we need to check auth
  final List<Widget> pages = [
    const HomeScreen(),
    const StatsScreen(),
    const MessagesScreen(),
    const CalculatorScreen(),
    const SettingsScreen(),
  ];

  final icons = const [
    Icons.apartment,
    Icons.pie_chart_outline,
    Icons.chat_bubble_outline,
    Icons.calculate_outlined,
    Icons.settings_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final isGuest = FirebaseAuth.instance.currentUser == null;

    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white, boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ]),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(icons.length, (i) {
              final sel = i == index;
              return GestureDetector(
                onTap: () {
                  // Block guest from Messages (index 2) and Settings (index 4)
                  if (isGuest && (i == 2 || i == 4)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Please create an account to access this feature!'),
                          backgroundColor: kNavy),
                    );
                  } else {
                    setState(() => index = i);
                  }
                },
                child: Container(
                  width: 44,
                  height: 44,
                  color: sel ? kTeal : Colors.transparent,
                  child: Icon(icons[i], color: sel ? Colors.white : kGrey),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}