import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class AppImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

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
