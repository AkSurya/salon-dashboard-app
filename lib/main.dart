import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  // 1. Initialize Flutter engine
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Check phone memory for login status
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  // 3. Start the app
  runApp(SalonOwnerApp(startScreen: isLoggedIn ? DashboardScreen() : AuthScreen()));
}

class SalonOwnerApp extends StatelessWidget {
  final Widget startScreen;
  SalonOwnerApp({required this.startScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.teal, useMaterial3: true),
      home: startScreen, // Dynamically chooses Login or Dashboard
    );
  }
}