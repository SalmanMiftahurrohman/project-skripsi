import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/constants/app_colors.dart';

class MapWidget extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final bool isReadOnly;
  final Function(double lat, double lng)? onLocationChanged;
  final bool showGeofence;

  const MapWidget({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.isReadOnly = false,
    this.onLocationChanged,
    this.showGeofence = true,
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  late final MapController _mapController;
  LatLng? _selectedLocation;

  // Pusat Kecamatan Kadungora, Garut
  static const double _kadungoraLat = -7.0880;
  static const double _kadungoraLng = 107.8620;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLocation = LatLng(widget.initialLatitude!, widget.initialLongitude!);
    }
  }

  @override
  void didUpdateWidget(covariant MapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialLatitude != oldWidget.initialLatitude ||
        widget.initialLongitude != oldWidget.initialLongitude) {
      if (widget.initialLatitude != null && widget.initialLongitude != null) {
        setState(() {
          _selectedLocation = LatLng(widget.initialLatitude!, widget.initialLongitude!);
        });
        _mapController.move(_selectedLocation!, _mapController.camera.zoom);
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
        child: FlutterMap(
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
            if (_selectedLocation != null)
              MarkerLayer(
                markers: [
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
                ],
              ),
          ],
        ),
      ),
    );
  }
}
