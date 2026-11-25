import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'constants.dart';
import 'home_screen.dart';
import 'messages_screen.dart';
import 'calculator_screen.dart';
import 'settings_screen.dart';
import 'models.dart';
import 'widgets.dart';
import 'map_screen.dart';

class MainScreen extends StatefulWidget {
  final VoidCallback? onLoginRequested;
  const MainScreen({super.key, this.onLoginRequested});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int index = 0;

  final icons = const [
    Icons.apartment,        
    Icons.favorite_outline, 
    Icons.map_outlined,
    Icons.chat_bubble_outline, 
    Icons.calculate_outlined,
    Icons.settings_outlined,   
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onLoginRequested: widget.onLoginRequested), // Tab 0: Public
      const MyFavoritesScreen(),                             // Tab 1: Login required
      const MapScreen(),                                     // Tab 2: Public
      const MessagesScreen(),                                // Tab 3: Login required
      const CalculatorScreen(),                              // Tab 4: Public
      const SettingsScreen(),                                // Tab 5: Login required
    ];

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
              // Visitors cannot access Favorites (1), Messages (3) or Settings (5)
              final isLocked = (i == 1 || i == 3 || i == 5);
              final showLock = widget.onLoginRequested != null && isLocked;

              return GestureDetector(
                onTap: () {
                  if (showLock) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please create an account to access this feature!'),
                          backgroundColor: kNavy),
                    );
                  } else {
                    setState(() => index = i);
                  }
                },
                child: Container(
                  width: 40,
                  height: 44,
                  color: sel ? kTeal : Colors.transparent,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(icons[i], color: sel ? Colors.white : kGrey, size: 22),
                      if (showLock)
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Icon(
                            Icons.lock,
                            size: 12,
                            color: sel ? Colors.white70 : kGrey,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class MyFavoritesScreen extends StatefulWidget {
  const MyFavoritesScreen({super.key});

  @override
  State<MyFavoritesScreen> createState() => _MyFavoritesScreenState();
}

class _MyFavoritesScreenState extends State<MyFavoritesScreen> {
  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const PageHeader(title: 'My Favorites', showBack: false),
              const SizedBox(height: 20),
              Expanded(
                child: user == null 
                  ? const EmptyState(
                      icon: Icons.lock_outline,
                      title: 'Login required',
                      subtitle: 'Please log in to see your favorite properties.',
                    )
                  : FutureBuilder<List<dynamic>>(
                      future: Supabase.instance.client
                          .from('favorites')
                          .select('properties(*)')
                          .eq('user_id', user.id)
                          .order('created_at', ascending: false),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const EmptyState(
                            icon: Icons.error_outline,
                            title: 'Something went wrong',
                            subtitle: 'Could not load favorites.',
                          );
                        }
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const LoadingView();
                        }
                        
                        final favs = snapshot.data ?? [];
                        if (favs.isEmpty) {
                          return const EmptyState(
                            icon: Icons.favorite_border,
                            title: 'No favorites yet',
                            subtitle: 'Tap the heart on a property to save it here.',
                          );
                        }
                        
                        final properties = favs
                            .map((f) => Property.fromMap(f['properties']))
                            .toList();

                        return ListView.builder(
                          itemCount: properties.length,
                          itemBuilder: (_, i) => PropertyCard(
                            property: properties[i], 
                          ),
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