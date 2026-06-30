import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Widget [AppImage] bertanggung jawab menampilkan gambar secara efisien dari internet (network) 
/// maupun dari data string terenkode Base64 (memory).
/// 
/// Menyediakan dukungan otomatis untuk state loading progress indicator, decoding base64 secara aman, 
/// serta fallback image error builder jika URL gambar rusak atau kosong.
class AppImage extends StatelessWidget {
  /// Alamat tautan URL gambar atau representasi data URL Base64 (`data:image/...`).
  final String imageUrl;

  /// Ukuran lebar bingkai gambar (lebar container).
  final double? width;

  /// Ukuran tinggi bingkai gambar (tinggi container).
  final double? height;

  /// Mengatur bagaimana ukuran gambar disesuaikan dengan bingkainya ([BoxFit]).
  final BoxFit fit;

  /// Widget placeholder kustom ketika gambar jaringan sedang dimuat.
  final Widget? placeholder;

  /// Widget fallback kustom ketika gambar gagal dimuat atau URL kosong.
  final Widget? errorWidget;

  /// Membuat instance baru dari [AppImage].
  const AppImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fallbackError = errorWidget ?? Container(
      width: width,
      height: height,
      color: isDark ? AppColors.borderDark : AppColors.border,
      child: const Icon(Icons.broken_image, color: AppColors.textSecondary),
    );

    if (imageUrl.isEmpty) {
      return fallbackError;
    }

    if (!imageUrl.startsWith('http') && !imageUrl.startsWith('data:image/')) {
      try {
        return Image.file(
          File(imageUrl),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => fallbackError,
        );
      } catch (e) {
        return fallbackError;
      }
    }

    if (imageUrl.startsWith('data:image/')) {
      try {
        final base64Content = imageUrl.split(',').last;
        final bytes = base64Decode(base64Content);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => fallbackError,
        );
      } catch (e) {
        return fallbackError;
      }
    }

    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => fallbackError,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? Container(
          width: width,
          height: height,
          color: isDark ? AppColors.borderDark : AppColors.border,
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
    );
  }
}
