import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Widget [LoadingOverlay] digunakan untuk menumpuk overlay loading berlatar belakang blur/buram
/// di atas widget utama ([child]) saat proses asinkron ([isLoading]) bernilai true.
class LoadingOverlay extends StatelessWidget {
  /// Status aktif overlay loading. Jika `true`, layar buram dengan loading indicator akan muncul.
  final bool isLoading;

  /// Widget utama/anak yang diletakkan di bawah overlay loading.
  final Widget child;

  /// Membuat instance baru dari [LoadingOverlay].
  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: Center(
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Memproses...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
