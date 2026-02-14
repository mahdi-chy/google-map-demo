import 'package:flutter/material.dart';
import 'package:my_google_maps_app/home_screen.dart';

void main() {
  runApp(GoogleMapsDemo());
}

class GoogleMapsDemo extends StatelessWidget {
  const GoogleMapsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: HomeScreen());
  }
}
