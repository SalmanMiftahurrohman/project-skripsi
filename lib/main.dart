import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'core/constants/app_strings.dart';
import 'core/themes/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/complaint_provider.dart';
import 'providers/feedback_provider.dart';
import 'providers/config_provider.dart';
import 'router/app_router.dart';

/// Titik masuk (entry point) utama untuk menjalankan aplikasi GO - SAMPAH.
/// 
/// Fungsi ini menginisialisasi Flutter bindings, melakukan konfigurasi format tanggal lokal
/// berbahasa Indonesia ('id_ID'), serta menginisialisasi modul Firebase.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

/// Kelas [MyApp] adalah root widget utama dari aplikasi GO - SAMPAH.
/// 
/// Menggunakan [MultiProvider] untuk menyematkan state provider global seperti:
/// - [AuthProvider] untuk otentikasi.
/// - [ComplaintProvider] untuk manajemen laporan sampah.
/// - [FeedbackProvider] untuk ulasan kepuasan.
/// - [ConfigProvider] untuk pengaturan admin.
class MyApp extends StatelessWidget {
  /// Membuat instance baru dari [MyApp].
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider<ComplaintProvider>(
          create: (_) => ComplaintProvider(),
        ),
        ChangeNotifierProvider<FeedbackProvider>(
          create: (_) => FeedbackProvider(),
        ),
        ChangeNotifierProvider<ConfigProvider>(
          create: (_) => ConfigProvider(),
        ),
      ],
      child: const AppContent(),
    );
  }
}

/// Kelas [AppContent] mengatur pembangunan [MaterialApp.router].
/// 
/// Widget ini menggunakan konfigurasi [AppRouter] untuk routing, menentukan [AppTheme]
/// untuk visualisasi terang/gelap, serta menyinkronkan tema visual dengan pengaturan sistem perangkat.
class AppContent extends StatelessWidget {
  /// Membuat instance baru dari [AppContent].
  const AppContent({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router(context),
    );
  }
}
