import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/prayer_timing.dart';

class PrayerTimingService {
  static const String _baseUrl = 'http://api.aladhan.com/v1/timings';

  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low));
  }

  Future<PrayerTiming?> getTodayTimings() async {
    try {
      final position = await _determinePosition();
      if (position == null) {
        return null; // Handle properly in UI
      }

      final date = DateTime.now();
      final dateStr = '${date.day}-${date.month}-${date.year}';
      
      final url = '$_baseUrl/$dateStr?latitude=${position.latitude}&longitude=${position.longitude}&method=1';
      
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PrayerTiming.fromJson(data['data']);
      }
    } catch (e) {
      debugPrint('Error fetching prayer times: $e');
    }
    return null;
  }
}
