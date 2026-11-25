import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'all_properties_screen.dart';
import 'constants.dart';
import 'widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool uploadingAvatar = false;

  String _name(User? user) {
    if (user == null) return '';
    final meta = user.userMetadata;
    if (meta != null && meta['name'] != null) return meta['name'].toString();
    return (user.email ?? 'User').split('@').first;
  }

  Future<void> _uploadAvatar() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70, maxWidth: 500);
    if (picked == null) return;

    setState(() => uploadingAvatar = true);
    try {
      final file = File(picked.path);
      final fileName = '${user.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final supabase = Supabase.instance.client;
      await supabase.storage.from('properties').upload(fileName, file);
      final url = supabase.storage.from('properties').getPublicUrl(fileName);

      await supabase.auth.updateUser(UserAttributes(data: {'avatar_url': url}));
      await supabase.from('profiles').update({'avatar_url': url}).eq('id', user.id);

      if (mounted) showMsg(context, 'Profile picture updated!');
    } catch (e) {
      if (mounted) showMsg(context, 'Error uploading picture: $e');
    } finally {
      if (mounted) setState(() => uploadingAvatar = false);
    }
  }

  Future<void> _removeAvatar() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    
    final ok = await confirmDialog(context, 'Remove Photo', 'Do you want to remove your profile picture?');
    if (!ok) return;

    setState(() => uploadingAvatar = true);
    try {
      final supabase = Supabase.instance.client;
      await supabase.auth.updateUser(UserAttributes(data: {'avatar_url': ''}));
      await supabase.from('profiles').update({'avatar_url': null}).eq('id', user.id);
      if (mounted) showMsg(context, 'Profile picture removed.');
    } catch (e) {
      if (mounted) showMsg(context, 'Error removing picture: $e');
    } finally {
      if (mounted) setState(() => uploadingAvatar = false);
    }
  }

  Future<void> _editName(BuildContext context) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    
    final ctrl = TextEditingController(text: _name(user));
    
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(),
        title: const Text('Edit name', style: TextStyle(color: kNavy, fontWeight: FontWeight.w700)),
        content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(hintText: 'Your name')),
        actions: [
          TextButton(
            onPressed: () { FocusScope.of(ctx).unfocus(); Navigator.pop(ctx); },
            child: const Text('Cancel', style: TextStyle(color: kGrey)),
          ),
          TextButton(
            onPressed: () { FocusScope.of(ctx).unfocus(); Navigator.pop(ctx, ctrl.text.trim()); },
            child: const Text('Save', style: TextStyle(color: kTeal)),
          ),
        ],
      ),
    );

    if (newName == null || newName.isEmpty) return;
    
    try {
      await Supabase.instance.client.auth.updateUser(UserAttributes(data: {'name': newName}));
      await Supabase.instance.client.from('profiles').update({'name': newName}).eq('id', user.id);
      if (context.mounted) showMsg(context, 'Name updated successfully.');
    } catch (e) {
      if (context.mounted) showMsg(context, 'Could not update name: $e');
    }
  }

  Future<void> _resetPassword(BuildContext context) async {
    final email = Supabase.instance.client.auth.currentUser?.email;
    if (email == null) return;
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (context.mounted) showMsg(context, 'Password reset email sent to $email');
    } catch (e) {
      if (context.mounted) showMsg(context, 'Could not send the email: $e');
    }
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await confirmDialog(context, 'Log out', 'Do you want to log out?');
    if (!ok) return;
    await Supabase.instance.client.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: StreamBuilder<AuthState>(
            stream: Supabase.instance.client.auth.onAuthStateChange,
            builder: (context, snapshot) {
              final user = Supabase.instance.client.auth.currentUser;
              
              if (user == null) {
                return const Column(
                  children: [
                    PageHeader(title: 'Settings', showBack: false),
                    SizedBox(height: 40),
                    EmptyState(icon: Icons.lock_outline, title: 'Login required', subtitle: 'Please log in to access settings.'),
                  ],
                );
              }

              final name = _name(user);
              final avatarUrl = user.userMetadata?['avatar_url'] as String?;

              return Column(
                children: [
                  const PageHeader(title: 'Settings', showBack: false),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Row(children: [
                      GestureDetector(
                        onTap: uploadingAvatar ? null : (avatarUrl == null || avatarUrl.isEmpty ? _uploadAvatar : null),
                        child: Stack(
                          children: [
                            Avatar(url: avatarUrl, name: name, radius: 32),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: kTeal, shape: BoxShape.circle),
                                child: uploadingAvatar
                                    ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kNavy)),
                            const SizedBox(height: 4),
                            Text(user.email ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kGrey)),
                          ],
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  if (avatarUrl != null && avatarUrl.isNotEmpty)
                    _tile(Icons.delete_outline, 'Remove Profile Picture', _removeAvatar, color: kRed),
                  _tile(Icons.person_outline, 'Edit Name', () => _editName(context)),
                  _tile(Icons.home_work_outlined, 'My Properties', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AllPropertiesScreen(title: 'My Properties', ownerId: user.id)));
                  }),
                  _tile(Icons.lock_outline, 'Reset Password', () => _resetPassword(context)),
                  const SizedBox(height: 10),
                  TealButton(label: 'Log Out', width: double.infinity, onTap: () => _logout(context)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _tile(IconData icon, String label, VoidCallback onTap, {Color? color}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          color: Colors.white,
          child: Row(children: [
            IconTile(icon: icon),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: TextStyle(color: color ?? kNavy, fontWeight: FontWeight.w600))),
            const Icon(Icons.chevron_right, color: kGrey),
          ]),
        ),
      );
}