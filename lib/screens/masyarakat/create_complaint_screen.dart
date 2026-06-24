import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/location_validator.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complaint_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/map_widget.dart';

/// Halaman [CreateComplaintScreen] menyediakan antarmuka bagi masyarakat untuk membuat laporan pengaduan sampah baru.
/// 
/// Fitur utama meliputi pengunggahan foto sampah (kamera/galeri), penentuan lokasi gps otomatis atau pin manual 
/// pada peta [MapWidget], validasi cakupan geofencing Kecamatan Kadungora, serta form deskripsi laporan.
class CreateComplaintScreen extends StatefulWidget {
  /// Membuat instance baru dari [CreateComplaintScreen].
  const CreateComplaintScreen({super.key});

  @override
  State<CreateComplaintScreen> createState() => _CreateComplaintScreenState();
}

/// State untuk [CreateComplaintScreen] yang memantau validasi formulir laporan baru, gambar sampah, dan koordinat peta.
class _CreateComplaintScreenState extends State<CreateComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  double? _latitude;
  double? _longitude;
  String? _address;
  String _selectedCategory = 'Kebersihan';
  bool _isLocating = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // Pilih Foto Bukti (Kamera/Galeri)
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 50,
        maxWidth: 600,
        maxHeight: 600,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil gambar: $e')),
      );
    }
  }

  // Mengubah/memilih lokasi dari peta atau GPS
  Future<void> _onMapLocationChanged(double lat, double lng) async {
    if (!LocationValidator.isWithinKadungora(lat, lng)) {
      final distance = LocationValidator.distanceFromCenter(lat, lng).toStringAsFixed(1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lokasi di luar wilayah ${LocationValidator.kecamatanName}. '
            '(Jarak: ${distance}km dari pusat). Silakan pilih lokasi di dalam wilayah Kadungora.',
          ),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      setState(() {
        _latitude = null;
        _longitude = null;
        _address = null;
      });
      return;
    }

    setState(() {
      _latitude = lat;
      _longitude = lng;
      _address = 'Memuat alamat...';
    });

    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _address = '${place.street}, ${place.subLocality}, ${place.locality}, ${place.subAdministrativeArea}, ${place.administrativeArea}';
        });
      } else {
        setState(() {
          _address = 'Koordinat: $lat, $lng';
        });
      }
    } catch (e) {
      setState(() {
        _address = 'Koordinat: $lat, $lng';
      });
    }
  }

  // Mengambil Lokasi GPS & Alamat
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocating = true;
    });

    try {
      // 1. Periksa izin lokasi
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Izin akses lokasi ditolak oleh pengguna.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi ditolak secara permanen. Silakan aktifkan di pengaturan sistem.');
      }

      // 2. Dapatkan koordinat GPS
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      await _onMapLocationChanged(position.latitude, position.longitude);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      setState(() {
        _isLocating = false;
      });
    }
  }

  // Mengirim Laporan Pengaduan
  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;

    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan sertakan foto bukti sampah terlebih dahulu.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    if (_latitude == null || _longitude == null || _address == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan tentukan koordinat lokasi pengaduan Anda.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final complaintProvider = Provider.of<ComplaintProvider>(context, listen: false);
    
    final userId = authProvider.user?.uid;
    if (userId == null) return;

    final success = await complaintProvider.createComplaint(
      userId: userId,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      category: _selectedCategory,
      imageFile: _imageFile!,
      latitude: _latitude!,
      longitude: _longitude!,
      address: _address!,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laporan pengaduan berhasil dikirim!'),
          backgroundColor: AppColors.statusSelesai,
        ),
      );
      context.pop(); // Kembali ke HomeScreen
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(complaintProvider.errorMessage ?? 'Gagal mengirim laporan.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final complaintProvider = Provider.of<ComplaintProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Pengaduan Sampah'),
      ),
      body: LoadingOverlay(
        isLoading: complaintProvider.isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: AppColors.primary),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Sertakan informasi foto dan lokasi yang jelas agar laporan Anda dapat segera ditindaklanjuti.',
                          style: TextStyle(fontSize: 13, color: AppColors.primary, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Form Inputs
                CustomTextField(
                  controller: _titleController,
                  labelText: 'Judul Laporan',
                  hintText: 'Misal: Tumpukan sampah liar di trotoar',
                  prefixIcon: Icons.title_rounded,
                  validator: Validators.validateRequired,
                ),
                const SizedBox(height: 16),

                // Input Dropdown Kategori
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Kategori Pengaduan',
                    prefixIcon: const Icon(Icons.category, color: AppColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                    ),
                  ),
                  items: ['Kebersihan', 'Limbah B3', 'Sampah Plastik', 'Lainnya']
                      .map((category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedCategory = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _descController,
                  labelText: 'Deskripsi Detail / Keterangan',
                  hintText: 'Sebutkan jenis sampah, volume perkiraan, atau detail spesifik lainnya...',
                  prefixIcon: Icons.description_outlined,
                  maxLines: 3,
                  validator: Validators.validateRequired,
                ),
                const SizedBox(height: 24),

                // Area Upload Gambar
                Text(
                  'Foto Bukti Sampah',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _buildImageSelectorCard(isDark),
                const SizedBox(height: 24),

                // Area Lokasi
                Text(
                  'Lokasi Kejadian',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: TextEditingController(text: _address ?? ''),
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Lokasi Pengaduan',
                          hintText: 'Dapatkan koordinat GPS atau ketuk peta...',
                          prefixIcon: const Icon(Icons.location_on, color: Colors.redAccent),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLocating ? null : _getCurrentLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLocating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Icon(Icons.my_location),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                MapWidget(
                  initialLatitude: _latitude,
                  initialLongitude: _longitude,
                  isReadOnly: false,
                  onLocationChanged: _onMapLocationChanged,
                ),
                if (_latitude != null && _longitude != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Koordinat GPS: $_latitude, $_longitude',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
                const SizedBox(height: 40),

                // Submit Button
                ElevatedButton(
                  onPressed: _submitComplaint,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), // Pill-shaped button
                    ),
                  ),
                  child: const Text('Kirim Pengaduan', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSelectorCard(bool isDark) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (context) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                  title: const Text('Ambil Foto dari Kamera'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: AppColors.primary),
                  title: const Text('Pilih Foto dari Galeri'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : Colors.grey[400]!,
            width: 1,
          ),
        ),
        child: _imageFile != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_imageFile!, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _imageFile = null;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt,
                    size: 48,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ambil Foto Untuk Membuat Pengaduan',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }
}

