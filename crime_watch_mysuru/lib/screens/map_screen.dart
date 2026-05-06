import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<Map<String, dynamic>> _hotspots = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getHotspots();
      if (!mounted) return;
      setState(() { _hotspots = data; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Color _spotColor(int count) {
    if (count > 1500) return const Color(0xFFEF4444);
    if (count > 800)  return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D2E),
        title: const Text('Crime Hotspot Map'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(12.2958, 76.6394),
                initialZoom: 10,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.mysuru.crimewatch',
                ),
                CircleLayer(
                  circles: _hotspots.map((h) {
                    final count = (h['count'] as num).toInt();
                    final radius = (count / 10).clamp(8.0, 40.0);
                    return CircleMarker(
                      point: LatLng((h['lat'] as num).toDouble(), (h['lon'] as num).toDouble()),
                      radius: radius,
                      color: _spotColor(count).withOpacity(0.5),
                      borderColor: _spotColor(count),
                      borderStrokeWidth: 2,
                    );
                  }).toList(),
                ),
                MarkerLayer(
                  markers: _hotspots.map((h) {
                    final count = (h['count'] as num).toInt();
                    return Marker(
                      point: LatLng((h['lat'] as num).toDouble(), (h['lon'] as num).toDouble()),
                      width: 120,
                      height: 40,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1D2E).withOpacity(0.9),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: _spotColor(count)),
                            ),
                            child: Text(
                              '${h['Area']}\n$count crimes',
                              style: TextStyle(fontSize: 10, color: _spotColor(count)),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
    );
  }
}
