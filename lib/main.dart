import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'auth_screen.dart';
import 'constants.dart';
import 'firebase_options.dart';
import 'main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ImmoApp());
}

class ImmoApp extends StatelessWidget {
  const ImmoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Immobilier',
      theme: ThemeData(
        scaffoldBackgroundColor: kBg,
        colorScheme: ColorScheme.fromSeed(seedColor: kTeal),
        textTheme: GoogleFonts.urbanistTextTheme(),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: kTeal)),
          );
        }
        if (snapshot.hasData) return const MainScreen();
        return const AuthScreen();
      },
    );
  }
}