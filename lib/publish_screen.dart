import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';

import 'constants.dart';
import 'models.dart';
import 'widgets.dart';

class PublishScreen extends StatefulWidget {
  const PublishScreen({super.key});

  @override
  State<PublishScreen> createState() => _PublishScreenState();
}

class _PublishScreenState extends State<PublishScreen> {
  final _formKey = GlobalKey<FormState>();
  final titleCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final bedsCtrl = TextEditingController();
  final sqftCtrl = TextEditingController();
  final picker = ImagePicker();

  String category = kCategories[0];
  File? image;
  bool loading = false;

  @override
  void dispose() {
    titleCtrl.dispose();
    priceCtrl.dispose();
    locationCtrl.dispose();
    descCtrl.dispose();
    bedsCtrl.dispose();
    sqftCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80, maxWidth: 1600);
    if (picked != null) setState(() => image = File(picked.path));
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    if (image == null) {
      showMsg(context, 'Please choose a photo of the property.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => loading = true);

    try {
      final ref = FirebaseStorage.instance.ref().child(
          'properties/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(image!);
      final imageUrl = await ref.getDownloadURL();

      double? lat;
      double? lng;
      try {
        final results = await locationFromAddress(locationCtrl.text.trim());
        if (results.isNotEmpty) {
          lat = results.first.latitude;
          lng = results.first.longitude;
        }
      } catch (_) {}

      final property = Property(
        id: '',
        title: titleCtrl.text.trim(),
        description: descCtrl.text.trim(),
        location: locationCtrl.text.trim(),
        imageUrl: imageUrl,
        category: category,
        ownerId: user.uid,
        ownerName: (user.displayName != null && user.displayName!.isNotEmpty)
            ? user.displayName!
            : (user.email ?? 'User'),
        price: double.parse(priceCtrl.text.trim()),
        bedrooms: int.tryParse(bedsCtrl.text.trim()) ?? 0,
        sqft: int.tryParse(sqftCtrl.text.trim()) ?? 0,
        latitude: lat,
        longitude: lng,
        createdAt: DateTime.now(),
      );
      await FirebaseFirestore.instance
          .collection('properties')
          .add(property.toMap());

      navigator.pop();
      messenger.showSnackBar(SnackBar(
        content: const Text('Property published!'),
        backgroundColor: kNavy,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(),
      ));
    } catch (e) {
      if (mounted) showMsg(context, 'Could not publish: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'This field is required' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            children: [
              const PageHeader(title: 'Publish Property'),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            height: 190,
                            width: double.infinity,
                            color: Colors.white,
                            child: image == null
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.add_photo_alternate_outlined,
                                          size: 40, color: kTeal),
                                      SizedBox(height: 8),
                                      Text('Tap to choose a photo',
                                          style: TextStyle(color: kGrey)),
                                    ],
                                  )
                                : Image.file(image!, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(height: 18),
                        AppTextField(
                          controller: titleCtrl,
                          hint: 'Title',
                          icon: Icons.title,
                          validator: _required,
                        ),
                        const SizedBox(height: 14),
                        const Text('Category',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, color: kNavy)),
                        const SizedBox(height: 8),
                        Row(
                          children: List.generate(kCategories.length, (i) {
                            final selected = category == kCategories[i];
                            return Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => category = kCategories[i]),
                                child: Container(
                                  height: 46,
                                  margin: EdgeInsets.only(
                                      right: i == kCategories.length - 1 ? 0 : 8),
                                  alignment: Alignment.center,
                                  color: selected ? kTeal : Colors.white,
                                  child: Text(kCategories[i],
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: selected
                                              ? Colors.white
                                              : kNavy)),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          controller: priceCtrl,
                          hint: 'Price per month (\$)',
                          icon: Icons.attach_money,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (v) {
                            final n = double.tryParse((v ?? '').trim());
                            return (n == null || n <= 0)
                                ? 'Enter a valid price'
                                : null;
                          },
                        ),
                        const SizedBox(height: 14),
                        Row(children: [
                          Expanded(
                            child: AppTextField(
                              controller: bedsCtrl,
                              hint: 'Bedrooms',
                              icon: Icons.bed_outlined,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AppTextField(
                              controller: sqftCtrl,
                              hint: 'Sqft',
                              icon: Icons.square_foot,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ]),
                        const SizedBox(height: 14),
                        AppTextField(
                          controller: locationCtrl,
                          hint: 'Location (e.g. 123 Park Ave, New York)',
                          icon: Icons.location_on_outlined,
                          validator: _required,
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          controller: descCtrl,
                          hint: 'Description',
                          maxLines: 4,
                          validator: _required,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TealButton(
                label: 'Publish',
                width: double.infinity,
                loading: loading,
                onTap: _publish,
              ),
            ],
          ),
        ),
      ),
    );
  }
}