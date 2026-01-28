import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const TaskFlowApp());
}

class TaskFlowApp extends StatelessWidget {
  const TaskFlowApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: const MaterialColor(0xFF4F46E5, {
          50: Color(0xFFEEEFF9),
          100: Color(0xFFDBD8F3),
          200: Color(0xFFBCB5EB),
          300: Color(0xFF9D91E3),
          400: Color(0xFF7D6EDB),
          500: Color(0xFF4F46E5),
          600: Color(0xFF4A3FD0),
          700: Color(0xFF4338BA),
          800: Color(0xFF3A32A3),
          900: Color(0xFF2D267B),
        }),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Cool White
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF4F46E5), // Vibrant Indigo Blue
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFFF1F5F9), // Light Slate
          hintStyle: TextStyle(color: Color(0xFF94A3B8)), // Light Slate
          labelStyle: TextStyle(color: Color(0xFF64748B)), // Slate Grey
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFE2E8F0)), // Soft Grey
          ),
          focusedBorder: OutlineInputBorder(
            borderSide:
                BorderSide(color: Color(0xFF4F46E5)), // Vibrant Indigo Blue
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5), // Vibrant Indigo Blue
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFF64748B)), // Slate Grey
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 1)); // Splash delay

    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFF4F46E5), // Vibrant Indigo Blue
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.task_alt,
                size: 80,
                color: Colors.white,
              ),
              SizedBox(height: 20),
              Text(
                'TaskFlow',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Task Management Simplified',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
