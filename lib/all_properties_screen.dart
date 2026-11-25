import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      itemBuilder: (_, i) => PropertyCard(property: list[i]),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (ownerId != null) {
      body = FutureBuilder<List<dynamic>>(
        future: Supabase.instance.client
            .from('properties')
            .select()
            .eq('owner_id', ownerId!)
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const EmptyState(
              icon: Icons.error_outline,
              title: 'Something went wrong',
              subtitle: 'Could not load your properties.',
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          final list = (snapshot.data ?? [])
              .map((data) => Property.fromMap(data))
              .toList();
          return _list(list);
        },
      );
    } else {
      body = _list(items ?? []);
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          // FIXED MARGIN HERE
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              PageHeader(title: title),
              const SizedBox(height: 20),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }
}