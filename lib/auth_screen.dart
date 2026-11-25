import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'constants.dart';
import 'widgets.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onVisitorSelected;
  const AuthScreen({super.key, required this.onVisitorSelected});

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

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await Future.delayed(const Duration(milliseconds: 300));

    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);
    
    try {
      final supabase = Supabase.instance.client;
      
      if (isLogin) {
        await supabase.auth.signInWithPassword(
          email: emailCtrl.text.trim(),
          password: passCtrl.text,
        ).timeout(const Duration(seconds: 10));
      } else {
        final res = await supabase.auth.signUp(
          email: emailCtrl.text.trim(),
          password: passCtrl.text,
        ).timeout(const Duration(seconds: 10));
        
        if (res.user != null) {
          await supabase.from('profiles').insert({
            'id': res.user!.id,
            'name': nameCtrl.text.trim(),
            'email': emailCtrl.text.trim(),
          }).timeout(const Duration(seconds: 10));
        }
      }
    } on AuthException catch (e) {
      if (mounted) showMsg(context, 'Auth Error: ${e.message}');
    } catch (e) {
      if (mounted) showMsg(context, 'Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await Future.delayed(const Duration(milliseconds: 300));

    final email = emailCtrl.text.trim();
    if (email.isEmpty) {
      showMsg(context, 'Enter your email first.');
      return;
    }
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email)
          .timeout(const Duration(seconds: 10));
      if (mounted) showMsg(context, 'Password reset email sent.');
    } catch (e) {
      if (mounted) showMsg(context, 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // HERE IS THE NEW LOGO
                      Image.asset(
                        'assets/images/icon.png',
                        width: 100,
                        height: 100,
                        fit: BoxFit.contain,
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
                            onPressed: () =>
                                setState(() => hidePass = !hidePass),
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
                        loading: false,
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
                            onTap: () {
                              FocusManager.instance.primaryFocus?.unfocus();
                              setState(() => isLogin = !isLogin);
                            },
                            child: Text(isLogin ? 'Register' : 'Login',
                                style: const TextStyle(
                                    color: kTeal,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
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
                          FocusManager.instance.primaryFocus?.unfocus();
                          widget.onVisitorSelected();
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
            if (loading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(color: kTeal),
                ),
              ),
          ],
        ),
      ),
    );
  }
}