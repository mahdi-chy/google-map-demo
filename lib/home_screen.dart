import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart'; // Import geolocator
import 'dart:async'; // Import for StreamSubscription

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? _googleMapController; // Made nullable
  bool _locationPermissionGranted = false;
  StreamSubscription<Position>? _positionStreamSubscription; // To listen for location changes
  List<LatLng> _polylineCoordinates = []; // Stores points for the polyline
  LatLng? _currentLocation; // Stores the user's current location
  Marker? _userMarker; // Stores the user's marker

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel(); // Cancel the location stream
    _googleMapController?.dispose(); // Dispose the map controller
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      setState(() {
        _locationPermissionGranted = true;
      });
      _startLocationUpdates(); // Start listening for location updates
    } else if (status.isDenied) {
      _showPermissionDeniedDialog(context);
    } else if (status.isPermanentlyDenied) {
      _showPermissionPermanentlyDeniedDialog(context);
    }
  }

  void _startLocationUpdates() {
    if (!_locationPermissionGranted) return;

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
          final newLatLng = LatLng(position.latitude, position.longitude);
          setState(() {
            _currentLocation = newLatLng;
            _polylineCoordinates.add(newLatLng); // Add new point to polyline

            // Update marker
            _userMarker = Marker(
              markerId: const MarkerId("user_location"),
              position: newLatLng,
              infoWindow: InfoWindow(
                title: "My Current Location",
                snippet:
                    "Lat: ${newLatLng.latitude.toStringAsFixed(4)}, Lng: ${newLatLng.longitude.toStringAsFixed(4)}",
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure,
              ), // A different color for user
            );

            // Move camera to current location
            _googleMapController?.animateCamera(CameraUpdate.newLatLng(newLatLng));
          });
        });
  }

  void _showPermissionDeniedDialog(BuildContext context) {
    // TODO: Implement a user-friendly dialog or snackbar
    print("Location permission denied.");
  }

  void _showPermissionPermanentlyDeniedDialog(BuildContext context) {
    // TODO: Implement a user-friendly dialog and offer to open app settings
    print("Location permission permanently denied. Please enable it in settings.");
    openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Home Screen")),
      body: _locationPermissionGranted
          ? (_currentLocation == null && _polylineCoordinates.isEmpty)
                ? const Center(
                    child: CircularProgressIndicator(),
                  ) // Show loading until first location
                : GoogleMap(
                    mapType: MapType.normal,
                    trafficEnabled: true,
                    myLocationButtonEnabled: true,
                    myLocationEnabled: true,
                    initialCameraPosition: CameraPosition(
                      target:
                          _currentLocation ??
                          const LatLng(
                            22.502981851772283,
                            91.81071211436299,
                          ), // Use current location if available, else default
                      zoom: 19,
                    ),
                    onMapCreated: (GoogleMapController controller) {
                      _googleMapController = controller;
                      // If location is already available, animate camera to it
                      if (_currentLocation != null) {
                        _googleMapController?.animateCamera(
                          CameraUpdate.newLatLng(_currentLocation!),
                        );
                      }
                    },
                    markers: _userMarker != null ? {_userMarker!} : {}, // Display user marker
                    polylines: {
                      Polyline(
                        polylineId: const PolylineId("user_path"),
                        points: _polylineCoordinates,
                        color: Colors.blue, // Color of the polyline
                        width: 5, // Width of the polyline
                      ),
                    },
                  )
          : Center(child: CircularProgressIndicator()),
    );
  }
}
