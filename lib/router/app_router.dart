import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_routes.dart';
import '../providers/auth_provider.dart';

// Import Screens
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/register_citizen_screen.dart';
import '../screens/auth/register_officer_screen.dart';
import '../screens/auth/forgot_password_screen.dart';

// Masyarakat screens
import '../screens/masyarakat/home_screen.dart';
import '../screens/masyarakat/create_complaint_screen.dart';
import '../screens/masyarakat/complaint_detail_screen.dart';
import '../screens/masyarakat/profile_screen.dart';

// Petugas screens
import '../screens/petugas/officer_home_screen.dart';
import '../screens/petugas/officer_complaint_detail_screen.dart';

// Admin screens
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_complaints_screen.dart';
import '../screens/admin/admin_users_screen.dart';
import '../screens/admin/admin_officers_screen.dart';
import '../screens/admin/admin_config_screen.dart';

class AppRouter {
  static GoRouter router(BuildContext context) {
    return GoRouter(
      initialLocation: AppRoutes.splash,
      redirect: (context, state) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final isLoggedIn = authProvider.user != null;
        final userRole = authProvider.userRole;

        final isGoingToSplash = state.matchedLocation == AppRoutes.splash;
        final isGoingToAuth = state.matchedLocation == AppRoutes.login ||
            state.matchedLocation == AppRoutes.register ||
            state.matchedLocation == AppRoutes.registerCitizen ||
            state.matchedLocation == AppRoutes.registerOfficer ||
            state.matchedLocation == AppRoutes.forgotPassword;

        // Jika tidak login dan tidak sedang menuju halaman Auth/Splash, lempar ke login
        if (!isLoggedIn && !isGoingToAuth && !isGoingToSplash) {
          return AppRoutes.login;
        }

        // Jika sudah login dan mencoba ke halaman auth/splash, redirect ke home masing-masing role
        if (isLoggedIn && (isGoingToAuth || isGoingToSplash)) {
          if (userRole == 'masyarakat') {
            return AppRoutes.citizenHome;
          } else if (userRole == 'petugas') {
            return AppRoutes.officerHome;
          } else if (userRole == 'admin') {
            return AppRoutes.adminDashboard;
          }
          return AppRoutes.login;
        }

        // Proteksi Route berdasarkan Role
        final isGoingToCitizenRoute = state.matchedLocation.startsWith('/masyarakat');
        final isGoingToOfficerRoute = state.matchedLocation.startsWith('/petugas');
        final isGoingToAdminRoute = state.matchedLocation.startsWith('/admin');

        if (isLoggedIn) {
          if (isGoingToCitizenRoute && userRole != 'masyarakat') {
            return _getHomeRouteForRole(userRole);
          }
          if (isGoingToOfficerRoute && userRole != 'petugas') {
            return _getHomeRouteForRole(userRole);
          }
          if (isGoingToAdminRoute && userRole != 'admin') {
            return _getHomeRouteForRole(userRole);
          }
        }

        return null;
      },
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: AppRoutes.register,
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: AppRoutes.registerCitizen,
          builder: (context, state) => const RegisterCitizenScreen(),
        ),
        GoRoute(
          path: AppRoutes.registerOfficer,
          builder: (context, state) => const RegisterOfficerScreen(),
        ),
        GoRoute(
          path: AppRoutes.forgotPassword,
          builder: (context, state) => const ForgotPasswordScreen(),
        ),

        // Masyarakat Routes
        GoRoute(
          path: AppRoutes.citizenHome,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: AppRoutes.citizenCreateComplaint,
          builder: (context, state) => const CreateComplaintScreen(),
        ),
        GoRoute(
          path: AppRoutes.citizenComplaintDetail,
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return ComplaintDetailScreen(id: id);
          },
        ),
        GoRoute(
          path: AppRoutes.profile,
          builder: (context, state) => const ProfileScreen(),
        ),

        // Petugas Routes
        GoRoute(
          path: AppRoutes.officerHome,
          builder: (context, state) => const OfficerHomeScreen(),
        ),
        GoRoute(
          path: AppRoutes.officerComplaintDetail,
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return OfficerComplaintDetailScreen(id: id);
          },
        ),

        // Admin Routes
        GoRoute(
          path: AppRoutes.adminDashboard,
          builder: (context, state) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: AppRoutes.adminComplaints,
          builder: (context, state) => const AdminComplaintsScreen(),
        ),
        GoRoute(
          path: AppRoutes.adminUsers,
          builder: (context, state) => const AdminUsersScreen(),
        ),
        GoRoute(
          path: AppRoutes.adminOfficers,
          builder: (context, state) => const AdminOfficersScreen(),
        ),
        GoRoute(
          path: AppRoutes.adminConfig,
          builder: (context, state) => const AdminConfigScreen(),
        ),
      ],
    );
  }

  static String _getHomeRouteForRole(String? role) {
    if (role == 'masyarakat') return AppRoutes.citizenHome;
    if (role == 'petugas') return AppRoutes.officerHome;
    if (role == 'admin') return AppRoutes.adminDashboard;
    return AppRoutes.login;
  }
}
