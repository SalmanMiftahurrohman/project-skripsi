import 'dart:math';

/// Validator lokasi untuk memastikan laporan hanya diterima
/// dari wilayah Kecamatan Kadungora, Kabupaten Garut, Jawa Barat
class LocationValidator {
  /// Koordinat garis lintang (latitude) pusat administratif Kecamatan Kadungora, Garut.
  static const double _centerLat = -7.0880;

  /// Koordinat garis bujur (longitude) pusat administratif Kecamatan Kadungora, Garut.
  static const double _centerLng = 107.8620;

  /// Radius maksimum batas wilayah Kecamatan Kadungora dalam satuan kilometer (km).
  /// Diatur ke 7.5 km agar mencakup seluruh desa terluar mengingat bentuk batas administratif yang tidak beraturan.
  static const double _maxRadiusKm = 7.5;

  /// Nama wilayah Kecamatan yang divalidasi.
  static const String kecamatanName = 'Kecamatan Kadungora';

  /// Nama Kabupaten tempat wilayah berada.
  static const String kabupatenName = 'Kabupaten Garut';

  /// Nama Provinsi tempat wilayah berada.
  static const String provinsiName = 'Jawa Barat';

  /// Mengecek apakah koordinat [latitude] dan [longitude] berada di dalam radius wilayah Kecamatan Kadungora.
  /// 
  /// Mengembalikan `true` jika jarak koordinat tersebut dari pusat kurang dari atau sama dengan [_maxRadiusKm].
  static bool isWithinKadungora(double latitude, double longitude) {
    final double distanceKm = _haversineDistance(
      _centerLat,
      _centerLng,
      latitude,
      longitude,
    );
    return distanceKm <= _maxRadiusKm;
  }

  /// Menghitung jarak antara dua koordinat menggunakan formula Haversine (dalam km).
  /// 
  /// Menerima parameter [lat1] & [lng1] sebagai titik asal, dan [lat2] & [lng2] sebagai titik tujuan.
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

  /// Mendapatkan jarak numerik dalam kilometer antara koordinat [latitude] dan [longitude] 
  /// dengan koordinat pusat Kecamatan Kadungora ([_centerLat], [_centerLng]).
  static double distanceFromCenter(double latitude, double longitude) {
    return _haversineDistance(_centerLat, _centerLng, latitude, longitude);
  }

  /// Mengonversi nilai sudut [degrees] (derajat) menjadi radian.
  static double _toRadians(double degrees) {
    return degrees * pi / 180.0;
  }
}
