import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'models.dart';
import 'widgets.dart';

class AllPropertiesScreen extends StatelessWidget {
  final String title;
  final List<Property>? items;
  final String? ownerId;

  const AllPropertiesScreen(
      {super.key, required this.title, this.items, this.ownerId});

  Widget _list(List<Property> list) {
    if (list.isEmpty) {
      return const EmptyState(
        icon: Icons.home_work_outlined,
        title: 'Nothing here yet',
        subtitle: 'No properties to show.',
      );
    }
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (_, i) => PropertyCard(property: list[i], width: null),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (ownerId != null) {
      body = StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('properties')
            .where('ownerId', isEqualTo: ownerId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const EmptyState(
              icon: Icons.error_outline,
              title: 'Something went wrong',
              subtitle: 'Could not load your properties.',
            );
          }
          if (!snapshot.hasData) return const LoadingView();
          final list = snapshot.data!.docs
              .map((d) => Property.fromMap(d.data(), d.id))
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return _list(list);
        },
      );
    } else {
      body = _list(items ?? []);
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 4, 0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: PageHeader(title: title),
              ),
              const SizedBox(height: 20),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }
}