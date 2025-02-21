import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(SmartStart());
}

class SmartStart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartStart',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF001F3F), // Main Navy Blue as seed color
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white, // White background for clean look
        appBarTheme: AppBarTheme(
          color: Color(0xFF001F3F), // Main navy blue for app bar
          foregroundColor: Colors.white, // White text/icons for contrast
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF001F3F)), // Navy text for body
          bodyMedium: TextStyle(color: Color(0xFF001732)), // Slightly darker navy for readability
          titleLarge: TextStyle(
            color: Color(0xFF001F3F), // Navy blue for headings
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
            textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
              side: BorderSide(color: Color(0xFF001F3F), width: 2), // Matches button color
            ),
            backgroundColor: Color(0xFF001F3F), // Main navy blue
            foregroundColor: Colors.white, // White text color
            elevation: 5, // Button shadow
          ),
        ),
      ),
      home: SplashScreen(),
      debugShowCheckedModeBanner: false, // Hides debug banner for clean UI
    );
  }
}
