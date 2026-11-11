import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'constants.dart';
import 'widgets.dart';
import 'main_screen.dart'; // <-- ADDED IMPORT

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool isLogin = true;
  bool loading = false;
  bool hidePass = true;

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  String _message(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Wrong email or password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'network-request-failed':
        return 'No internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return e.message ?? 'Authentication error.';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);
    try {
      final auth = FirebaseAuth.instance;
      if (isLogin) {
        await auth.signInWithEmailAndPassword(
            email: emailCtrl.text.trim(), password: passCtrl.text);
      } else {
        final cred = await auth.createUserWithEmailAndPassword(
            email: emailCtrl.text.trim(), password: passCtrl.text);
        await cred.user?.updateDisplayName(nameCtrl.text.trim());
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) showMsg(context, _message(e));
    } catch (e) {
      if (mounted) showMsg(context, 'Something went wrong: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = emailCtrl.text.trim();
    if (email.isEmpty) {
      showMsg(context, 'Enter your email first.');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) showMsg(context, 'Password reset email sent.');
    } on FirebaseAuthException catch (e) {
      if (mounted) showMsg(context, _message(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    color: kTeal,
                    child: const Icon(Icons.apartment,
                        color: Colors.white, size: 38),
                  ),
                  const SizedBox(height: 24),
                  Text(isLogin ? 'Welcome Back' : 'Create Account',
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: kNavy)),
                  const SizedBox(height: 8),
                  Text(
                      isLogin
                          ? 'Login to find your dream property'
                          : 'Register to start renting and publishing',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: kGrey, fontSize: 15)),
                  const SizedBox(height: 30),
                  if (!isLogin) ...[
                    AppTextField(
                      controller: nameCtrl,
                      hint: 'Full name',
                      icon: Icons.person_outline,
                      validator: (v) => (v == null || v.trim().length < 2)
                          ? 'Enter your name'
                          : null,
                    ),
                    const SizedBox(height: 14),
                  ],
                  AppTextField(
                    controller: emailCtrl,
                    hint: 'Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || !v.contains('@'))
                        ? 'Enter a valid email'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      AppTextField(
                        controller: passCtrl,
                        hint: 'Password',
                        icon: Icons.lock_outline,
                        obscure: hidePass,
                        validator: (v) => (v == null || v.length < 6)
                            ? 'At least 6 characters'
                            : null,
                      ),
                      IconButton(
                        icon: Icon(
                            hidePass
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: kGrey),
                        onPressed: () => setState(() => hidePass = !hidePass),
                      ),
                    ],
                  ),
                  if (isLogin)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _forgotPassword,
                        child: const Text('Forgot password?',
                            style: TextStyle(color: kTeal)),
                      ),
                    )
                  else
                    const SizedBox(height: 14),
                  const SizedBox(height: 6),
                  TealButton(
                    label: isLogin ? 'Login' : 'Register',
                    width: double.infinity,
                    loading: loading,
                    onTap: _submit,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                          isLogin
                              ? "Don't have an account? "
                              : 'Already have an account? ',
                          style: const TextStyle(color: kGrey)),
                      GestureDetector(
                        onTap: () => setState(() => isLogin = !isLogin),
                        child: Text(isLogin ? 'Register' : 'Login',
                            style: const TextStyle(
                                color: kTeal, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // --- NEW VISITOR BUTTON ---
                  Row(
                    children: const [
                      Expanded(child: Divider(color: kGrey)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text("OR", style: TextStyle(color: kGrey)),
                      ),
                      Expanded(child: Divider(color: kGrey)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const MainScreen()),
                      );
                    },
                    child: const Text('Continue as Visitor',
                        style: TextStyle(
                            color: kNavy,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}