import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToLogin();
  }

  Future<void> _navigateToLogin() async {
    // Wait for 2 seconds then navigate to login
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      context.goNamed('login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Icon
            ClipRRect(
              borderRadius: BorderRadiusGeometry.circular(40),
              child: Image.asset(
                'assets/images/logo_aplikasi_silsilah_keluarga.png',
                cacheWidth: 200,
                alignment: AlignmentGeometry.center,
              ),
            ),
            const SizedBox(height: 16),
            // App Title
            const Text(
              'Tali Silsilah',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            // Subtitle
            const Text(
              'Al-usrah',
              style: TextStyle(
                fontSize: 20,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic
              ),
            ),
          ],
        ),
      ),
    );
  }
}
