import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../services/api_service.dart';

class VerificationScreen extends StatefulWidget {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String password;
  final String type;
  final String? courses;

  VerificationScreen({
    required this.id,
    required this.firstName,
    required this.lastName, 
    required this.email,
    required this.password,
    required this.type,
    this.courses,
  });

  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final TextEditingController codeController = TextEditingController();

  Future<void> _verifyCode() async {
    final code = codeController.text.trim();

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter the verification code.")),
      );
      return;
    }

    try {

      final verifyResponse = await ApiService.verifyCode(widget.email, code);


      if (verifyResponse['status'] == 'success') {
        // Step 2: Register the user
        print("📩 Registering with type from widget: ${widget.type}");
        
        final registerResponse = await ApiService.registerUser(
          int.parse(widget.id),
          widget.firstName,
          widget.lastName,
          widget.email,
          widget.password,
          widget.type,
          widget.courses,
        );

        if (registerResponse['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("✅ Verified and user registered!")),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("❌ ${registerResponse['message']}")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ ${verifyResponse['message']}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Network error")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Verify Your Email')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'A verification code has been sent to ${widget.email}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            TextField(
              controller: codeController,
              decoration: InputDecoration(
                labelText: 'Enter 6-digit code',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _verifyCode,
              child: Text('Verify'),
            ),
          ],
        ),
      ),
    );
  }
}
