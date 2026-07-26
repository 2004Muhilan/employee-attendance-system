import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../providers/office_provider.dart'; // <--- Import

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng? _userLocation;
  bool _isLoadingUserLocation = true;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  // We only need to fetch the USER location now.
  // Office location is already in memory!
  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Location services are disabled.';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'Location permissions are denied';
      }

      Position pos = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _userLocation = LatLng(pos.latitude, pos.longitude);
          _isLoadingUserLocation = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingUserLocation = false);
      print("GPS Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // READ FROM PROVIDER
    final office = Provider.of<OfficeProvider>(context).office;

    // Handle case where office data is missing (e.g. error during login)
    if (office == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Office Map")),
        body: const Center(child: Text("No office assigned or failed to load.")),
      );
    }

    final officeLocation = LatLng(office.latitude, office.longitude);

    return Scaffold(
      appBar: AppBar(title: Text(office.name), backgroundColor: Colors.white),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: officeLocation,
              initialZoom: 16.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.defab_engineering.attendance_app',
              ),
              // GEOFENCE CIRCLE
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: officeLocation,
                    color: Colors.green.withOpacity(0.3),
                    borderStrokeWidth: 2,
                    borderColor: Colors.green,
                    radius: office.radius,
                    useRadiusInMeter: true,
                  ),
                ],
              ),
              // MARKERS
              MarkerLayer(
                markers: [
                  // Office
                  Marker(
                    point: officeLocation,
                    width: 80,
                    height: 80,
                    child: const Column(
                      children: [
                        Icon(Icons.business, color: Colors.purple, size: 40),
                        Text("Office", style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  // User
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 80,
                      height: 80,
                      child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
                    ),
                ],
              ),
              SimpleAttributionWidget(
                alignment: Alignment.topRight,
                source: const Text(
                  'OpenStreetMap contributors',
                  style: TextStyle(color: Colors.black87, fontSize: 12),
                ),
                onTap: () {
                  // We will add the url_launcher code here next!
                },
              ),
            ],
          ),
          // Info Card (Optional)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              child: ListTile(
                title: Text(office.name),
                subtitle: Text(office.address),
                trailing: _isLoadingUserLocation
                    ? const CircularProgressIndicator()
                    : IconButton(
                  icon: const Icon(Icons.my_location),
                  onPressed: () {
                    if(_userLocation != null) _mapController.move(_userLocation!, 16);
                  },
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}