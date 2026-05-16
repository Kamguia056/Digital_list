import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/student_register_screen.dart'; 
import 'screens/teacher_request_screen.dart';
import 'screens/teacher_register_screen.dart';
import 'screens/student_home_screen.dart';
import 'screens/validation_success_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/teacher_qr_screen.dart';
import 'screens/teacher_profile_screen.dart';
import 'screens/teacher_home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital List',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/student_register': (context) => const StudentRegisterScreen(),
        '/teacher_request': (context) => const TeacherRequestScreen(),
        '/teacher_register': (context) => const TeacherRegisterScreen(),
        '/student_home': (context) => const StudentHomeScreen(),
        '/validation_success': (context) => const ValidationSuccessScreen(),
        '/scanner': (context) => const ScannerScreen(),
        '/teacher_qr': (context) => const TeacherQRScreen(),
        '/teacher_profile': (context) => const TeacherProfileScreen(),
        '/teacher_home': (context) => const TeacherHomeScreen(),
      },
      theme: ThemeData(
        primaryColor: Colors.blue,
        useMaterial3: true,
      ),
    );
  }
}