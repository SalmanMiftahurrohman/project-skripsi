class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String registerCitizen = '/register/citizen';
  static const String registerOfficer = '/register/officer';
  static const String forgotPassword = '/forgot-password';

  // Masyarakat (Citizen) Routes
  static const String citizenHome = '/masyarakat/home';
  static const String citizenCreateComplaint = '/masyarakat/complaint/create';
  static const String citizenComplaintDetail = '/masyarakat/complaint/:id';
  static const String profile = '/profile';

  // Petugas (Officer) Routes
  static const String officerHome = '/petugas/home';
  static const String officerComplaintDetail = '/petugas/complaint/:id';

  // Admin Routes
  static const String adminDashboard = '/admin/dashboard';
  static const String adminComplaints = '/admin/complaints';
  static const String adminUsers = '/admin/users';
  static const String adminOfficers = '/admin/officers';
  static const String adminConfig = '/admin/config';

  // Navigation helpers to generate paths with parameters
  static String getCitizenComplaintDetailPath(String id) => '/masyarakat/complaint/$id';
  static String getOfficerComplaintDetailPath(String id) => '/petugas/complaint/$id';
}
