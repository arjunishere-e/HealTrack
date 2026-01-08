import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    _listenAuthAndNavigate();
  }

  void _listenAuthAndNavigate() {
    // Show splash for a short moment then react to auth state
    Future.delayed(const Duration(milliseconds: 600), () {
      _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
        if (!mounted) return;
        if (user != null) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.home,
            (route) => false,
          );
        } else {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.login,
            (route) => false,
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(0, 128, 95, 1),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/icon.jpg',
              height: 200,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.healing,
                    color: Colors.white, size: 120);
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'HealTrack',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                fontFamily: 'Josefin Sans',
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
