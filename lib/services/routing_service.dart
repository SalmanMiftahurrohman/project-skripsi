import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

/// Layanan [RoutingService] menyediakan fungsi untuk mengambil koordinat rute 
/// perjalanan (driving/walking) antara dua titik koordinat dari API OSRM (Open Source Routing Machine) publik.
class RoutingService {
  /// Mengambil rute perjalanan dari [start] (titik mulai/petugas) ke [end] (titik tujuan/pengaduan).
  /// 
  /// Mengembalikan daftar koordinat [LatLng] sepanjang rute jalan,
  /// atau list kosong jika terjadi kegagalan/error.
  static Future<List<LatLng>> getRoute(LatLng start, LatLng end) async {
    final client = HttpClient();
    
    // Set timeout koneksi 5 detik
    client.connectionTimeout = const Duration(seconds: 5);

    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
        '?overview=full&geometries=geojson'
      );
      
      final request = await client.getUrl(url);
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> data = json.decode(responseBody);
        
        final List<dynamic> routes = data['routes'] ?? [];
        if (routes.isNotEmpty) {
          final Map<String, dynamic> route = routes[0];
          final Map<String, dynamic> geometry = route['geometry'] ?? {};
          final List<dynamic> coordinates = geometry['coordinates'] ?? [];
          
          return coordinates.map<LatLng>((coord) {
            // Koordinat dari OSRM berformat [longitude, latitude]
            final double lng = (coord[0] as num).toDouble();
            final double lat = (coord[1] as num).toDouble();
            return LatLng(lat, lng);
          }).toList();
        }
      } else {
        debugPrint('OSRM routing request failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching route from OSRM: $e');
    } finally {
      client.close();
    }
    
    return [];
  }
}
