import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'all_properties_screen.dart';
import 'constants.dart';
import 'widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  String _name(User? user) {
    if (user == null) return '';
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    return (user.email ?? 'User').split('@').first;
  }

  Future<void> _editName(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ctrl = TextEditingController(text: user.displayName ?? '');
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(),
        title: const Text('Edit name',
            style: TextStyle(color: kNavy, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Your name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: kGrey))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Save', style: TextStyle(color: kTeal))),
        ],
      ),
    );
    ctrl.dispose();
    if (newName == null || newName.isEmpty) return;
    try {
      await user.updateDisplayName(newName);
      if (context.mounted) showMsg(context, 'Name updated.');
    } catch (e) {
      if (context.mounted) showMsg(context, 'Could not update name: $e');
    }
  }

  Future<void> _resetPassword(BuildContext context) async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (context.mounted) showMsg(context, 'Password reset email sent to $email');
    } catch (e) {
      if (context.mounted) showMsg(context, 'Could not send the email: $e');
    }
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await confirmDialog(context, 'Log out', 'Do you want to log out?');
    if (!ok) return;
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.userChanges(),
            initialData: FirebaseAuth.instance.currentUser,
            builder: (context, snapshot) {
              final user = snapshot.data;
              final name = _name(user);
              return Column(
                children: [
                  const PageHeader(title: 'Settings', showBack: false),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Row(children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: kTeal,
                        child: Text(name.isEmpty ? '?' : name[0].toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: kNavy)),
                            const SizedBox(height: 4),
                            Text(user?.email ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: kGrey)),
                          ],
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  _tile(Icons.person_outline, 'Edit Name',
                      () => _editName(context)),
                  _tile(Icons.home_work_outlined, 'My Properties', () {
                    if (user == null) return;
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => AllPropertiesScreen(
                                title: 'My Properties', ownerId: user.uid)));
                  }),
                  _tile(Icons.lock_outline, 'Reset Password',
                      () => _resetPassword(context)),
                  const SizedBox(height: 10),
                  TealButton(
                    label: 'Log Out',
                    width: double.infinity,
                    onTap: () => _logout(context),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _tile(IconData icon, String label, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          color: Colors.white,
          child: Row(children: [
            IconTile(icon: icon),
            const SizedBox(width: 14),
            Expanded(
                child: Text(label,
                    style: const TextStyle(
                        color: kNavy, fontWeight: FontWeight.w600))),
            const Icon(Icons.chevron_right, color: kGrey),
          ]),
        ),
      );
}