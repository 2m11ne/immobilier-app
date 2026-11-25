import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'constants.dart';
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
  double? lat;
  double? lng;
  bool isCheckingAddress = false;

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
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1600);
    if (picked != null) setState(() => image = File(picked.path));
  }

  Future<void> _checkAddress(String address) async {
    if (address.trim().length < 3) return;
    setState(() => isCheckingAddress = true);
    try {
      final results = await locationFromAddress(address.trim());
      if (results.isNotEmpty) {
        setState(() {
          lat = results.first.latitude;
          lng = results.first.longitude;
        });
      }
    } catch (e) {
      setState(() {
        lat = null;
        lng = null;
      });
    } finally {
      setState(() => isCheckingAddress = false);
    }
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    if (image == null) {
      showMsg(context, 'Please choose a photo of the property.');
      return;
    }
    if (lat == null || lng == null) {
      showMsg(context, 'Please enter a valid real-world address.');
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => loading = true);

    try {
      final fileName = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final supabase = Supabase.instance.client;
      
      await supabase.storage.from('properties').upload(fileName, image!);
      final imageUrl = supabase.storage.from('properties').getPublicUrl(fileName);

      final profile = await supabase.from('profiles').select('name').eq('id', user.id).maybeSingle();
      final ownerName = profile?['name'] ?? user.email ?? 'User';

      await supabase.from('properties').insert({
        'title': titleCtrl.text.trim(),
        'description': descCtrl.text.trim(),
        'location': locationCtrl.text.trim(),
        'image_url': imageUrl,
        'category': category,
        'owner_id': user.id,
        'owner_name': ownerName,
        'price': double.parse(priceCtrl.text.trim()),
        'bedrooms': int.tryParse(bedsCtrl.text.trim()) ?? 0,
        'sqft': int.tryParse(sqftCtrl.text.trim()) ?? 0,
        'latitude': lat,
        'longitude': lng,
      });

      navigator.pop();
      messenger.showSnackBar(const SnackBar(
        content: Text('Property published!'),
        backgroundColor: kNavy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(),
      ));
    } catch (e) {
      if (mounted) showMsg(context, 'Could not publish: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'This field is required' : null;

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
                                      Icon(Icons.add_photo_alternate_outlined, size: 40, color: kTeal),
                                      SizedBox(height: 8),
                                      Text('Tap to choose a photo', style: TextStyle(color: kGrey)),
                                    ],
                                  )
                                : Image.file(image!, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(height: 18),
                        AppTextField(controller: titleCtrl, hint: 'Title', icon: Icons.title, validator: _required),
                        const SizedBox(height: 14),
                        const Text('Category', style: TextStyle(fontWeight: FontWeight.w700, color: kNavy)),
                        const SizedBox(height: 8),
                        Row(
                          children: List.generate(kCategories.length, (i) {
                            final selected = category == kCategories[i];
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => category = kCategories[i]),
                                child: Container(
                                  height: 46,
                                  margin: EdgeInsets.only(right: i == kCategories.length - 1 ? 0 : 8),
                                  alignment: Alignment.center,
                                  color: selected ? kTeal : Colors.white,
                                  child: Text(kCategories[i], style: TextStyle(fontWeight: FontWeight.w600, color: selected ? Colors.white : kNavy)),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          controller: priceCtrl,
                          hint: 'Price per month (TND)',
                          icon: Icons.attach_money,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (v) {
                            final n = double.tryParse((v ?? '').trim());
                            return (n == null || n <= 0) ? 'Enter a valid price' : null;
                          },
                        ),
                        const SizedBox(height: 14),
                        Row(children: [
                          Expanded(child: AppTextField(controller: bedsCtrl, hint: 'Bedrooms', icon: Icons.bed_outlined, keyboardType: TextInputType.number)),
                          const SizedBox(width: 10),
                          Expanded(child: AppTextField(controller: sqftCtrl, hint: 'Sqft', icon: Icons.square_foot, keyboardType: TextInputType.number)),
                        ]),
                        const SizedBox(height: 14),
                        AppTextField(controller: locationCtrl, hint: 'Location (e.g. 123 Park Ave, New York)', icon: Icons.location_on_outlined, validator: _required),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => _checkAddress(locationCtrl.text),
                            child: const Text('Verify Address on Map', style: TextStyle(color: kTeal)),
                          ),
                        ),
                        if (isCheckingAddress)
                          const Center(child: CircularProgressIndicator(color: kTeal))
                        else if (lat != null && lng != null)
                          Container(
                            height: 150,
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(border: Border.all(color: kTeal), borderRadius: BorderRadius.circular(8)),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: FlutterMap(
                                options: MapOptions(initialCenter: LatLng(lat!, lng!), initialZoom: 14.0, interactionOptions: const InteractionOptions(flags: InteractiveFlag.none)),
                                children: [
                                  TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.immobilier_app'),
                                  MarkerLayer(markers: [Marker(point: LatLng(lat!, lng!), width: 40, height: 40, child: const Icon(Icons.location_on, color: kRed, size: 40))]),
                                ],
                              ),
                            ),
                          )
                        else if (locationCtrl.text.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 14),
                            child: Text('Address not found. Please type a real city or street.', style: TextStyle(color: kRed)),
                          ),
                        const SizedBox(height: 14),
                        AppTextField(controller: descCtrl, hint: 'Description', maxLines: 4, validator: _required),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TealButton(label: 'Publish', width: double.infinity, loading: loading, onTap: _publish),
            ],
          ),
        ),
      ),
    );
  }
}