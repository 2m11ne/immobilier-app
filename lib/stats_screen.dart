import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'constants.dart';
import 'models.dart';
import 'widgets.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream;
  
  // FIXED: Use nullable String so it doesn't crash for Visitors
  String? get myId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _stream = FirebaseFirestore.instance.collection('properties').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const PageHeader(title: 'Statistics', showBack: false),
              const SizedBox(height: 24),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _stream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const EmptyState(
                        icon: Icons.error_outline,
                        title: 'Something went wrong',
                        subtitle: 'Could not load the statistics.',
                      );
                    }
                    if (!snapshot.hasData) return const LoadingView();

                    final items = snapshot.data!.docs
                        .map((d) => Property.fromMap(d.data(), d.id))
                        .toList();
                    if (items.isEmpty) {
                      return const EmptyState(
                        icon: Icons.pie_chart_outline,
                        title: 'No data yet',
                        subtitle: 'Statistics appear when properties are published.',
                      );
                    }

                    final total = items.length;
                    // FIXED: Handle null user
                    final mine = myId == null 
                        ? 0 
                        : items.where((p) => p.ownerId == myId).length;
                    final avg =
                        items.fold<double>(0, (s, p) => s + p.price) / total;

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            _stat(Icons.apartment, '$total', 'Properties'),
                            const SizedBox(width: 10),
                            _stat(Icons.person_outline, '$mine', 'Mine'),
                            const SizedBox(width: 10),
                            _stat(Icons.attach_money, money(avg), 'Avg / month'),
                          ]),
                          const SizedBox(height: 28),
                          const Text('By Category',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: kNavy)),
                          const SizedBox(height: 14),
                          ...kCategories.map((c) {
                            final count =
                                items.where((p) => p.category == c).length;
                            return _bar(c, count, total);
                          }),
                        ],
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

  Widget _stat(IconData icon, String value, String label) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconTile(icon: icon),
              const SizedBox(height: 12),
              FittedBox(
                child: Text(value,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: kNavy)),
              ),
              Text(label, style: const TextStyle(color: kGrey, fontSize: 13)),
            ],
          ),
        ),
      );

  Widget _bar(String label, int count, int total) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(color: kNavy)),
                Text('$count', style: const TextStyle(color: kGrey)),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: total == 0 ? 0 : count / total,
              minHeight: 8,
              backgroundColor: kTealLight,
              color: kTeal,
            ),
          ],
        ),
      );
}