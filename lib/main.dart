import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_screen.dart';
import 'constants.dart';
import 'main_screen.dart';

final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://myvyaelurwiljoprewhc.supabase.co',
    publishableKey: 'sb_publishable_tDeBuzaxWmYuUH3MZIvy1A_Q7N8xCZ8',
  );
  
  runApp(const ImmoApp());
}

class ImmoApp extends StatefulWidget {
  const ImmoApp({super.key});

  @override
  State<ImmoApp> createState() => _ImmoAppState();
}

class _ImmoAppState extends State<ImmoApp> {
  @override
  void initState() {
    super.initState();
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.signedOut) {
        navKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navKey,
      debugShowCheckedModeBanner: false,
      title: 'Darek',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.transparent, 
        colorScheme: ColorScheme.fromSeed(seedColor: kTeal),
        textTheme: GoogleFonts.urbanistTextTheme(),
      ),
      builder: (context, child) {
        return Stack(
          children: [
            // 1. The Background Image
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background.png'),
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter, 
                ),
              ),
            ),
            // 2. The White Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.95), // Top is solid white for text
                    Colors.white.withOpacity(0.60), // Middle is semi-transparent
                    Colors.white.withOpacity(0.10), // Bottom shows the waves
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            // 3. The actual app screen
            if (child != null) child,
          ],
        );
      },
      home: const SplashScreen(),
    );
  }
}

// ---------------------------------------------------------
// THE NEW SPLASH SCREEN (4 SECONDS)
// ---------------------------------------------------------
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthGate()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Image.asset(
          'assets/images/splash.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// THE AUTH GATE
// ---------------------------------------------------------
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool showAuthScreen = false;

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      return const MainScreen();
    }

    if (showAuthScreen) {
      return AuthScreen(
        onVisitorSelected: () {
          setState(() => showAuthScreen = false);
        },
      );
    }

    return MainScreen(
      onLoginRequested: () {
        setState(() => showAuthScreen = true);
      },
    );
  }
}