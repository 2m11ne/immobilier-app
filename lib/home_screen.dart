import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'all_properties_screen.dart';
import 'auth_screen.dart'; // Added for Login button
import 'constants.dart';
import 'models.dart';
import 'publish_screen.dart';
import 'widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? category;
  String query = '';
  double? maxPrice;
  final priceCtrl = TextEditingController();

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream;
  final icons = const [Icons.apartment, Icons.home_outlined, Icons.business];

  @override
  void initState() {
    super.initState();
    _stream = FirebaseFirestore.instance
        .collection('properties')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  void dispose() {
    priceCtrl.dispose();
    super.dispose();
  }

  List<Property> _filter(List<Property> all) {
    final q = query.trim().toLowerCase();
    return all.where((p) {
      if (category != null && p.category != kCategories[category!]) {
        return false;
      }
      if (maxPrice != null && p.price > maxPrice!) return false;
      if (q.isNotEmpty &&
          !(p.title.toLowerCase().contains(q) ||
              p.location.toLowerCase().contains(q))) {
        return false;
      }
      return true;
    }).toList();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning 😊';
    if (h < 18) return 'Good Afternoon 😊';
    return 'Good Evening 😊';
  }

  String _displayName(User? user) {
    if (user == null) return 'Visitor';
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    return (user.email ?? 'User').split('@').first;
  }

  void _openFilter() {
    priceCtrl.text = maxPrice == null ? '' : money(maxPrice!);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, 24 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700, color: kNavy)),
            const SizedBox(height: 18),
            const Text('Maximum price per month (\$)',
                style: TextStyle(color: kGrey)),
            const SizedBox(height: 8),
            AppTextField(
              controller: priceCtrl,
              hint: 'e.g. 1500',
              icon: Icons.attach_money,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(
                child: TealButton(
                  label: 'Clear',
                  color: kGrey,
                  onTap: () {
                    setState(() => maxPrice = null);
                    Navigator.pop(ctx);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TealButton(
                  label: 'Apply',
                  onTap: () {
                    setState(
                        () => maxPrice = double.tryParse(priceCtrl.text.trim()));
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 0, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              const SizedBox(height: 24),
              _searchBar(),
              const SizedBox(height: 28),
              const Text('Categories',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700, color: kNavy)),
              const SizedBox(height: 14),
              _categories(),
              const SizedBox(height: 28),
              _featured(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featured() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.only(right: 20),
            child: EmptyState(
              icon: Icons.error_outline,
              title: 'Something went wrong',
              subtitle: 'Could not load the properties.',
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingView();
        }

        final all = snapshot.data!.docs
            .map((d) => Property.fromMap(d.data(), d.id))
            .toList();
        final list = _filter(all);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Featured Properties',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: kNavy)),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AllPropertiesScreen(
                          title: category == null
                              ? 'All Properties'
                              : kCategories[category!],
                          items: list,
                        ),
                      ),
                    ),
                    child: const Text('View All',
                        style: TextStyle(
                            color: kTeal,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (all.isEmpty)
              const Padding(
                padding: EdgeInsets.only(right: 20),
                child: EmptyState(
                  icon: Icons.home_work_outlined,
                  title: 'No properties yet',
                  subtitle: 'Tap the + button at the top to publish the first one.',
                ),
              )
            else if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.only(right: 20),
                child: EmptyState(
                  icon: Icons.search_off,
                  title: 'No property found',
                  subtitle: 'Try another search, category or price.',
                ),
              )
            else
              SizedBox(
                height: 340,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: list.length,
                  itemBuilder: (_, i) => PropertyCard(property: list[i]),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _header() => Padding(
        padding: const EdgeInsets.only(right: 20),
        child: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.userChanges(),
          initialData: FirebaseAuth.instance.currentUser,
          builder: (context, snap) {
            final name = _displayName(snap.data);
            final isGuest = snap.data == null;

            return Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: kTeal,
                  child: Text(name.isEmpty ? '?' : name[0].toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_greeting(),
                          style: const TextStyle(color: kGrey, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: kNavy)),
                    ],
                  ),
                ),
                
                // NEW LOGIC: Show Login button for guests, '+' for users
                isGuest
                    ? GestureDetector(
                        onTap: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AuthScreen()),
                            (route) => false,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: kTeal,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                    : GestureDetector(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const PublishScreen())),
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withAlpha(15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4))
                            ],
                          ),
                          child: const Icon(Icons.add, color: kTeal),
                        ),
                      ),
              ],
            );
          },
        ),
      );

  Widget _searchBar() => Padding(
        padding: const EdgeInsets.only(right: 20),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                color: Colors.white,
                child: TextField(
                  onChanged: (v) => setState(() => query = v),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Search Properties...',
                    hintStyle: TextStyle(color: kGrey),
                    icon: Icon(Icons.search, color: kGrey),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _openFilter,
              child: Container(
                height: 54,
                width: 54,
                color: kTeal,
                child: const Icon(Icons.tune, color: Colors.white),
              ),
            ),
          ],
        ),
      );

  Widget _categories() => Padding(
        padding: const EdgeInsets.only(right: 20),
        child: Row(
          children: List.generate(kCategories.length, (i) {
            final selected = i == category;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => category = selected ? null : i),
                child: Container(
                  height: 94,
                  margin: EdgeInsets.only(right: i == 2 ? 0 : 8),
                  padding: const EdgeInsets.all(12),
                  color: selected ? kTeal : Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconTile(icon: icons[i], selected: selected),
                      FittedBox(
                        child: Text(kCategories[i],
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: selected ? Colors.white : kNavy)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      );
}