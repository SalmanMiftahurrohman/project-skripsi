import 'dart:math';

/// Validator lokasi untuk memastikan laporan hanya diterima
/// dari wilayah Kecamatan Kadungora, Kabupaten Garut, Jawa Barat
class LocationValidator {
  // Koordinat pusat Kecamatan Kadungora, Garut
  static const double _centerLat = -7.0880;
  static const double _centerLng = 107.8620;

  // Radius maksimum wilayah Kadungora (dalam kilometer)
  // Kadungora luas ±43 km², radius ~7.5 km untuk melingkupi seluruh desa
  static const double _maxRadiusKm = 7.5;

  static const String kecamatanName = 'Kecamatan Kadungora';
  static const String kabupatenName = 'Kabupaten Garut';
  static const String provinsiName = 'Jawa Barat';

  /// Mengecek apakah koordinat berada di dalam wilayah Kecamatan Kadungora
  static bool isWithinKadungora(double latitude, double longitude) {
    final double distanceKm = _haversineDistance(
      _centerLat,
      _centerLng,
      latitude,
      longitude,
    );
    return distanceKm <= _maxRadiusKm;
  }

  /// Menghitung jarak antara dua koordinat menggunakan formula Haversine (dalam km)
  static double _haversineDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadiusKm = 6371.0;

    final double dLat = _toRadians(lat2 - lat1);
    final double dLng = _toRadians(lng2 - lng1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusKm * c;
  }

  /// Mendapatkan jarak dari pusat Kadungora dalam kilometer
  static double distanceFromCenter(double latitude, double longitude) {
    return _haversineDistance(_centerLat, _centerLng, latitude, longitude);
  }

  static double _toRadians(double degrees) {
    return degrees * pi / 180.0;
  }
}
