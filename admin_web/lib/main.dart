import 'package:flutter/material.dart';
import 'core/constants.dart';
import 'core/session.dart';
import 'core/notifikasi_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_web_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConstants.initBaseUrl();
  await NotifikasiService.init();

  final bool isLogin = await Session.sudahLogin();
  final String? role = await Session.getRole();

  runApp(AdminWebApp(isLoggedIn: isLogin && role == 'admin'));
}

class AdminWebApp extends StatelessWidget {
  final bool isLoggedIn;

  const AdminWebApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dashboard Admin Absensi Web',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.primaryColor,
          primary: AppConstants.primaryColor,
          secondary: AppConstants.secondaryColor,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: isLoggedIn ? const DashboardWebScreen() : const LoginScreen(),
    );
  }
}
