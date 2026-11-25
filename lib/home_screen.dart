import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'all_properties_screen.dart';
import 'constants.dart';
import 'models.dart';
import 'publish_screen.dart';
import 'widgets.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onLoginRequested;
  const HomeScreen({super.key, this.onLoginRequested});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? category;
  String query = '';
  double? maxPrice;
  final priceCtrl = TextEditingController();

  final icons = const [Icons.apartment, Icons.home_outlined, Icons.business];

  List<Property> _filter(List<Property> all) {
    final q = query.trim().toLowerCase();
    return all.where((p) {
      if (category != null && p.category != kCategories[category!]) return false;
      if (maxPrice != null && p.price > maxPrice!) return false;
      if (q.isNotEmpty && !(p.title.toLowerCase().contains(q) || p.location.toLowerCase().contains(q))) return false;
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
    final meta = user.userMetadata;
    if (meta != null && meta['name'] != null) return meta['name'].toString();
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
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: kNavy)),
            const SizedBox(height: 18),
            const Text('Maximum price per month (TND)', style: TextStyle(color: kGrey)),
            const SizedBox(height: 8),
            AppTextField(
              controller: priceCtrl,
              hint: 'e.g. 1500',
              icon: Icons.attach_money,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                    setState(() => maxPrice = double.tryParse(priceCtrl.text.trim()));
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              const SizedBox(height: 24),
              _searchBar(),
              const SizedBox(height: 28),
              const Text('Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kNavy)),
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
    return FutureBuilder<List<dynamic>>(
      future: Supabase.instance.client.from('properties').select().order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const EmptyState(
            icon: Icons.error_outline,
            title: 'Something went wrong',
            subtitle: 'Could not load the properties.',
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingView();
        }

        final all = (snapshot.data ?? []).map((data) => Property.fromMap(data)).toList();
        final list = _filter(all);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Featured Properties', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kNavy)),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AllPropertiesScreen(
                        title: category == null ? 'All Properties' : kCategories[category!],
                        items: list,
                      ),
                    ),
                  ),
                  child: const Text('View All', style: TextStyle(color: kTeal, fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (all.isEmpty)
              const EmptyState(
                icon: Icons.home_work_outlined,
                title: 'No properties yet',
                subtitle: 'Tap the + button at the top to publish the first one.',
              )
            else if (list.isEmpty)
              const EmptyState(
                icon: Icons.search_off,
                title: 'No property found',
                subtitle: 'Try another search, category or price.',
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: list.length,
                itemBuilder: (_, i) => PropertyCard(property: list[i]),
              ),
          ],
        );
      },
    );
  }

  Widget _header() => StreamBuilder<AuthState>(
    stream: Supabase.instance.client.auth.onAuthStateChange,
    builder: (context, snap) {
      final user = Supabase.instance.client.auth.currentUser;
      final name = _displayName(user);
      final isGuest = user == null;
      final avatarUrl = user?.userMetadata?['avatar_url'] as String?;

      return Row(
        children: [
          Avatar(url: avatarUrl, name: name),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_greeting(), style: const TextStyle(color: kGrey, fontSize: 14)),
                const SizedBox(height: 2),
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kNavy)),
              ],
            ),
          ),
          isGuest
              ? GestureDetector(
                  onTap: () => widget.onLoginRequested?.call(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(color: kTeal, borderRadius: BorderRadius.circular(4)),
                    child: const Text('Login', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                )
              : GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PublishScreen())),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: const Icon(Icons.add, color: kTeal),
                  ),
                ),
        ],
      );
    },
  );

  Widget _searchBar() => Row(
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
  );

  Widget _categories() => Row(
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
                  child: Text(kCategories[i], style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: selected ? Colors.white : kNavy)),
                ),
              ],
            ),
          ),
        ),
      );
    }),
  );
}