import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'chat_screen.dart';
import 'constants.dart';
import 'models.dart';
import 'widgets.dart';

class DetailsScreen extends StatelessWidget {
  final Property property;
  const DetailsScreen({super.key, required this.property});

  bool get _isOwner =>
      FirebaseAuth.instance.currentUser?.uid == property.ownerId;

  Future<void> _rent(BuildContext context) async {
    // GUEST RESTRICTION
    if (FirebaseAuth.instance.currentUser == null) {
      showMsg(context, 'Please create an account to rent this property!');
      return;
    }
    
    final ok = await confirmDialog(context, 'Rent this property',
        'Send a rent request to ${property.ownerName}?');
    if (!ok || !context.mounted) return;
    try {
      await startChat(
        context,
        otherUid: property.ownerId,
        otherName: property.ownerName,
        firstMessage:
            'Hello, I am interested in renting "${property.title}".',
      );
    } catch (e) {
      if (context.mounted) showMsg(context, 'Could not send the request: $e');
    }
  }

  Future<void> _delete(BuildContext context) async {
    final ok = await confirmDialog(
        context, 'Delete property', 'This cannot be undone. Delete it?');
    if (!ok) return;
    try {
      await FirebaseFirestore.instance
          .collection('properties')
          .doc(property.id)
          .delete();
      try {
        await FirebaseStorage.instance.refFromURL(property.imageUrl).delete();
      } catch (_) {}
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) showMsg(context, 'Could not delete: $e');
    }
  }

  Widget _map() {
    final lat = property.latitude;
    final lng = property.longitude;
    if (lat == null || lng == null) {
      return Container(
        height: 80,
        width: double.infinity,
        color: Colors.white,
        alignment: Alignment.center,
        child: const Text('Map not available for this address',
            style: TextStyle(color: kGrey)),
      );
    }
    final position = LatLng(lat, lng);
    return SizedBox(
      height: 190,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(target: position, zoom: 14),
        markers: {
          Marker(
              markerId: MarkerId(property.id),
              position: position,
              infoWindow: InfoWindow(title: property.title))
        },
        zoomControlsEnabled: false,
        scrollGesturesEnabled: false,
        zoomGesturesEnabled: false,
        rotateGesturesEnabled: false,
        tiltGesturesEnabled: false,
        myLocationButtonEnabled: false,
        mapToolbarEnabled: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = property;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            children: [
              const PageHeader(title: 'Property Details'),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                          height: 260,
                          width: double.infinity,
                          child: NetImg(p.imageUrl)),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            color: kTealLight,
                            child: Text(p.category,
                                style: const TextStyle(
                                    color: kTeal,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ),
                          Flexible(
                            child: Text('by ${p.ownerName}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: kGrey, fontSize: 13)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(p.title,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: kNavy)),
                      const SizedBox(height: 10),
                      Row(children: [
                        const Icon(Icons.location_on_outlined,
                            color: kTeal, size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(p.location,
                              style: const TextStyle(
                                  color: kGrey, fontSize: 14)),
                        ),
                      ]),
                      const SizedBox(height: 24),
                      const Text('Specification',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: kNavy)),
                      const SizedBox(height: 14),
                      Row(children: [
                        SpecBox(
                            icon: Icons.square_foot, label: '${p.sqft} Sqft'),
                        const SizedBox(width: 10),
                        SpecBox(
                            icon: Icons.bed_outlined,
                            label: '${p.bedrooms} Bedroom'),
                        const SizedBox(width: 10),
                        SpecBox(
                            icon: Icons.apartment_outlined,
                            label: p.category),
                      ]),
                      const SizedBox(height: 24),
                      const Text('Description',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: kNavy)),
                      const SizedBox(height: 10),
                      Text(p.description,
                          style: const TextStyle(color: kGrey, height: 1.5)),
                      const SizedBox(height: 24),
                      const Text('Location',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: kNavy)),
                      const SizedBox(height: 14),
                      _map(),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Price',
                          style: TextStyle(color: kGrey, fontSize: 14)),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(children: [
                          TextSpan(
                              text: '\$${money(p.price)}',
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: kNavy)),
                          const TextSpan(
                              text: '/Month',
                              style: TextStyle(fontSize: 14, color: kNavy)),
                        ]),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (_isOwner && FirebaseAuth.instance.currentUser != null)
                    TealButton(
                        label: 'Delete',
                        width: 170,
                        color: kRed,
                        onTap: () => _delete(context))
                  else
                    TealButton(
                        label: 'Rent Now',
                        width: 170,
                        onTap: () => _rent(context)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}