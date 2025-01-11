import 'package:flutter/material.dart';
import 'signup_page.dart';
import 'login_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Signup and Login',
      theme: ThemeData(
        primarySwatch: Colors.lightBlue, // Set the theme to light blue
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false, // Hide debug banner
      initialRoute: '/login', // Set the initial page to login
      routes: {
        '/signup': (context) => SignupPage(), // Navigate to the signup page
        '/login': (context) => LoginPage(),   // Navigate to the login page
      },
    );
  }
}
