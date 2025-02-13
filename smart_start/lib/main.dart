import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'utils/theme.dart';

void main() {
  runApp(SmartStart());
}

class SmartStart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartStart',
      theme: appTheme, // Use the theme from utils
      home: SplashScreen(),
    );
  }
}

