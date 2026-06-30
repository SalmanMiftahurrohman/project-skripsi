import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/constants/app_colors.dart';
import '../services/routing_service.dart';

/// Widget [MapWidget] menampilkan peta interaktif menggunakan OpenStreetMap (OSM) dan [FlutterMap].
/// 
/// Digunakan untuk memilih lokasi penumpukan sampah (bagi masyarakat) atau melihat lokasi pengaduan (bagi petugas/admin).
/// Sekarang juga mendukung penampilan lokasi petugas dan menggambar rute jalan dari petugas ke tumpukan sampah.
class MapWidget extends StatefulWidget {
  /// Titik koordinat awal garis lintang (latitude) yang akan disorot peta.
  final double? initialLatitude;

  /// Titik koordinat awal garis bujur (longitude) yang akan disorot peta.
  final double? initialLongitude;

  /// Titik koordinat garis lintang (latitude) petugas lapangan.
  final double? officerLatitude;

  /// Titik koordinat garis bujur (longitude) petugas lapangan.
  final double? officerLongitude;

  /// Menentukan apakah peta hanya dapat dilihat saja (read-only) atau koordinatnya dapat digeser/dipilih.
  final bool isReadOnly;

  /// Callback event saat pengguna mengubah/mengetuk lokasi baru di peta (mengembalikan latitude & longitude baru).
  final Function(double lat, double lng)? onLocationChanged;

  /// Menentukan apakah batas wilayah administratif (geofence) Kecamatan Kadungora (7.5 km) perlu ditampilkan berupa lingkaran overlay.
  final bool showGeofence;

  /// Membuat instance baru dari [MapWidget].
  const MapWidget({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.officerLatitude,
    this.officerLongitude,
    this.isReadOnly = false,
    this.onLocationChanged,
    this.showGeofence = true,
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  /// Kontroler peta untuk mengatur pergerakan kamera zoom dan center lokasi.
  late final MapController _mapController;

  /// Menyimpan titik koordinat yang dipilih/diberi marker oleh pengguna.
  LatLng? _selectedLocation;

  /// Koordinat rute perjalanan antara petugas dan sampah
  List<LatLng> _routePoints = [];

  /// Indikator pemuatan rute dari API OSRM
  bool _isLoadingRoute = false;

  /// Garis lintang (latitude) pusat administratif Kecamatan Kadungora, Garut.
  static const double _kadungoraLat = -7.0880;

  /// Garis bujur (longitude) pusat administratif Kecamatan Kadungora, Garut.
  static const double _kadungoraLng = 107.8620;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLocation = LatLng(widget.initialLatitude!, widget.initialLongitude!);
    }
    _fetchRoute();
  }

  @override
  void didUpdateWidget(covariant MapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool shouldFetchRoute = false;

    if (widget.initialLatitude != oldWidget.initialLatitude ||
        widget.initialLongitude != oldWidget.initialLongitude) {
      if (widget.initialLatitude != null && widget.initialLongitude != null) {
        setState(() {
          _selectedLocation = LatLng(widget.initialLatitude!, widget.initialLongitude!);
        });
        _mapController.move(_selectedLocation!, _mapController.camera.zoom);
        shouldFetchRoute = true;
      }
    }

    if (widget.officerLatitude != oldWidget.officerLatitude ||
        widget.officerLongitude != oldWidget.officerLongitude) {
      shouldFetchRoute = true;
    }

    if (shouldFetchRoute) {
      _fetchRoute();
    }
  }

  /// Mengambil rute mengemudi dari lokasi petugas ke lokasi sampah menggunakan OSRM
  Future<void> _fetchRoute() async {
    if (widget.officerLatitude == null || 
        widget.officerLongitude == null || 
        _selectedLocation == null) {
      if (_routePoints.isNotEmpty) {
        setState(() {
          _routePoints = [];
        });
      }
      return;
    }

    setState(() {
      _isLoadingRoute = true;
    });

    try {
      final start = LatLng(widget.officerLatitude!, widget.officerLongitude!);
      final end = _selectedLocation!;
      final points = await RoutingService.getRoute(start, end);
      
      if (mounted) {
        setState(() {
          _routePoints = points;
        });
      }
    } catch (e) {
      debugPrint('Error loading route in map widget: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRoute = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final LatLng centerLatLng = _selectedLocation ?? const LatLng(_kadungoraLat, _kadungoraLng);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: centerLatLng,
                initialZoom: 13.5,
                maxZoom: 18.0,
                minZoom: 10.0,
                onTap: widget.isReadOnly
                    ? null
                    : (tapPosition, latLng) {
                        setState(() {
                          _selectedLocation = latLng;
                        });
                        _fetchRoute();
                        if (widget.onLocationChanged != null) {
                          widget.onLocationChanged!(latLng.latitude, latLng.longitude);
                        }
                      },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.gosampah.app',
                ),
                if (widget.showGeofence)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: const LatLng(_kadungoraLat, _kadungoraLng),
                        radius: 7500, // 7.5 km in meters
                        useRadiusInMeter: true,
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderColor: AppColors.primary.withValues(alpha: 0.4),
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),
                if (_routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        strokeWidth: 4.0,
                        color: Colors.blueAccent,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    if (_selectedLocation != null)
                      Marker(
                        point: _selectedLocation!,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.redAccent,
                          size: 40,
                        ),
                      ),
                    if (widget.officerLatitude != null && widget.officerLongitude != null)
                      Marker(
                        point: LatLng(widget.officerLatitude!, widget.officerLongitude!),
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.blueAccent,
                          size: 32,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (_isLoadingRoute)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
