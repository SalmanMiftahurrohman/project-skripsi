import 'package:cloud_firestore/cloud_firestore.dart';

/// Model data [UserModel] merepresentasikan profil pengguna di sistem GO - SAMPAH.
/// Model ini menampung informasi untuk semua jenis peran (role), yaitu masyarakat, petugas, dan admin.
class UserModel {
  /// ID unik pengguna yang dihasilkan oleh Firebase Authentication (UID).
  final String uid;

  /// Alamat email terdaftar pengguna.
  final String email;

  /// Nama lengkap pengguna.
  final String name;

  /// Peran hak akses pengguna di aplikasi.
  /// 
  /// Nilai yang valid: 'masyarakat', 'petugas', 'admin'.
  final String role;

  /// Nomor telepon aktif pengguna.
  final String phoneNumber;

  /// Tanggal lahir pengguna (format: DD-MM-YYYY).
  final String birthDate;

  /// Pekerjaan atau profesi pengguna saat ini.
  final String occupation;

  /// Alamat tempat tinggal pengguna saat ini.
  final String address;

  /// URL foto profil pengguna yang disimpan di Firebase Storage.
  final String profileImageUrl;

  /// Tanggal pembuatan akun pertama kali.
  final DateTime createdAt;

  /// Membuat instance baru dari [UserModel].
  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.phoneNumber,
    required this.birthDate,
    required this.occupation,
    required this.address,
    this.profileImageUrl = '',
    required this.createdAt,
  });

  /// Mengonversi map mentah dari Firestore ([map]) dan [uid] dokumen menjadi objek [UserModel].
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'masyarakat',
      phoneNumber: map['phoneNumber'] ?? '',
      birthDate: map['birthDate'] ?? '',
      occupation: map['occupation'] ?? '',
      address: map['address'] ?? '',
      profileImageUrl: map['profileImageUrl'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Mengonversi objek [UserModel] menjadi format [Map] untuk disimpan di Firestore.
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'phoneNumber': phoneNumber,
      'birthDate': birthDate,
      'occupation': occupation,
      'address': address,
      'profileImageUrl': profileImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Membuat salinan objek [UserModel] baru dengan mengubah beberapa atribut tertentu
  /// tanpa mengubah atribut lainnya yang ada.
  UserModel copyWith({
    String? name,
    String? phoneNumber,
    String? birthDate,
    String? occupation,
    String? address,
    String? profileImageUrl,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      role: role,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      birthDate: birthDate ?? this.birthDate,
      occupation: occupation ?? this.occupation,
      address: address ?? this.address,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt,
    );
  }
}
