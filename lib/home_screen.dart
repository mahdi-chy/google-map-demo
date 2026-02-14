import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? _googleMapController;
  bool _locationPermissionGranted = false;
  StreamSubscription<Position>? _positionStreamSubscription;
  List<LatLng> _polylineCoordinates = [];
  LatLng? _currentLocation;
  Marker? _userMarker;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _googleMapController?.dispose();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      setState(() {
        _locationPermissionGranted = true;
      });
      _startLocationUpdates();
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
      distanceFilter: 10,
    );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
          final newLatLng = LatLng(position.latitude, position.longitude);
          setState(() {
            _currentLocation = newLatLng;
            _polylineCoordinates.add(newLatLng);

            _userMarker = Marker(
              markerId: const MarkerId("user_location"),
              position: newLatLng,
              infoWindow: InfoWindow(
                title: "My Current Location",
                snippet:
                    "Lat: ${newLatLng.latitude.toStringAsFixed(4)}, Lng: ${newLatLng.longitude.toStringAsFixed(4)}",
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            );

            _googleMapController?.animateCamera(CameraUpdate.newLatLng(newLatLng));
          });
        });
  }

  void _showPermissionDeniedDialog(BuildContext context) {
    print("Location permission denied.");
  }

  void _showPermissionPermanentlyDeniedDialog(BuildContext context) {
    print("Location permission permanently denied. Please enable it in settings.");
    openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Home Screen")),
      body: _locationPermissionGranted
          ? (_currentLocation == null && _polylineCoordinates.isEmpty)
                ? const Center(child: CircularProgressIndicator())
                : GoogleMap(
                    mapType: MapType.normal,
                    trafficEnabled: true,
                    myLocationButtonEnabled: true,
                    myLocationEnabled: true,
                    initialCameraPosition: CameraPosition(
                      target:
                          _currentLocation ?? const LatLng(22.502981851772283, 91.81071211436299),
                      zoom: 19,
                    ),
                    onMapCreated: (GoogleMapController controller) {
                      _googleMapController = controller;

                      if (_currentLocation != null) {
                        _googleMapController?.animateCamera(
                          CameraUpdate.newLatLng(_currentLocation!),
                        );
                      }
                    },
                    markers: _userMarker != null ? {_userMarker!} : {},
                    polylines: {
                      Polyline(
                        polylineId: const PolylineId("user_path"),
                        points: _polylineCoordinates,
                        color: Colors.blue,
                        width: 5,
                      ),
                    },
                  )
          : Center(child: CircularProgressIndicator()),
    );
  }
}
