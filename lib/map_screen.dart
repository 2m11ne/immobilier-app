import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'constants.dart';
import 'models.dart';
import 'widgets.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<Marker> _markers = [];
  bool _isLoading = true;

  // Default camera position (Tunis, Tunisia)
  static const LatLng _initialPosition = LatLng(36.8065, 10.1815);

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    try {
      final data = await Supabase.instance.client.from('properties').select();
      
      final List<Marker> newMarkers = [];
      for (var item in data) {
        final p = Property.fromMap(item);
        if (p.latitude != null && p.longitude != null) {
          newMarkers.add(
            Marker(
              point: LatLng(p.latitude!, p.longitude!),
              width: 40,
              height: 40,
              child: const Icon(
                Icons.location_on,
                color: kRed,
                size: 40,
              ),
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _markers = newMarkers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showMsg(context, 'Could not load map properties: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: PageHeader(title: 'Properties Map', showBack: false),
            ),
            Expanded(
              child: _isLoading
                  ? const LoadingView()
                  : ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: FlutterMap(
                        options: const MapOptions(
                          initialCenter: _initialPosition,
                          initialZoom: 11.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.immobilier_app',
                          ),
                          MarkerLayer(
                            markers: _markers,
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}