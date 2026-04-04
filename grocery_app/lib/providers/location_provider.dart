import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationProvider extends ChangeNotifier {
  double? _latitude;
  double? _longitude;
  bool _isLoading = false;
  String? _error;

  double? get latitude => _latitude;
  double? get longitude => _longitude;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasLocation => _latitude != null && _longitude != null;

  Future<void> requestLocation() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;

    Future.microtask(() => notifyListeners());

    try {
      // Check if service is enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _error = 'Location services are disabled.';
        dev.log("location: service disabled", name: 'LocationProvider');
        return;
      }

      // Check / request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _error = 'Location permission denied.';
          dev.log("location: permission denied", name: 'LocationProvider');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _error = 'Location permission permanently denied.';
        dev.log("location: permission denied forever", name: 'LocationProvider');
        return;
      }

      // Get position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      _latitude = position.latitude;
      _longitude = position.longitude;
      dev.log("location: $_latitude, $_longitude", name: 'LocationProvider');
    } catch (e) {
      _error = 'Could not get location.';
      dev.log("location error: $e", name: 'LocationProvider');
    } finally {
      _isLoading = false;
      Future.microtask(() => notifyListeners());
    }
  }

  /// Haversine distance in km between user and a point
  double? distanceTo(double? lat, double? lng) {
    if (!hasLocation || lat == null || lng == null) return null;
    return Geolocator.distanceBetween(
          _latitude!, _longitude!, lat, lng) /
        1000; // metres → km
  }

  String formatDistance(double? lat, double? lng) {
    final d = distanceTo(lat, lng);
    if (d == null) return '';
    if (d < 1) return '${(d * 1000).toStringAsFixed(0)} m';
    return '${d.toStringAsFixed(1)} km';
  }
}