import 'package:flutter/material.dart';
import 'package:nova/features/auth/screens/login_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/home/homescreen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';

  static final Map<String, WidgetBuilder> routes = {
    splash: (_) => const SplashScreen(),
    login: (_) => const LoginScreen(),
    signup: (_) => const SignupScreen(),
    home: (_) => const HomeScreen(),
  };
}
