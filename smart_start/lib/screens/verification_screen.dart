import 'package:flutter/material.dart';
import 'login_screen.dart';

class VerificationScreen extends StatelessWidget {
  final String email;
  VerificationScreen({required this.email});
  final TextEditingController verificationCodeController = TextEditingController();

  void _verify(BuildContext context) {
  if (verificationCodeController.text == "123") {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Verification successful!',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF001F3F), // Navy Blue
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen(userType: 'Student')),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Invalid verification code',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF001F3F), // Navy Blue
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
    );
  }
}


  @override
Widget build(BuildContext context) {
   return Scaffold(
    appBar: AppBar(title: Text('Verify Your Email')),
     body: Stack(
       children: [
         Positioned.fill(
           child: Opacity(
             opacity: 0.35,
             child: Transform.scale(
               scale: 3.0, // Adjust zoom level here
             child: Center(
               child: Image.asset(
                 'assets/images/water_mark_logo.png', // Ensure correct asset path
                 fit: BoxFit.cover, // Adjusted for full-screen watermark
                 errorBuilder: (context, object, stackTrace) {
                   return const Text('Watermark Image Not Found!');
                 },
               ),
               ),
             ),
           ),
         ),
         Center(
           child: Padding(
             padding: const EdgeInsets.all(16.0),
             child: SingleChildScrollView(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
           Text(
             'A verification code has been sent to $email.',
             style: TextStyle(fontSize: 18),
           ),
           SizedBox(height: 20),
           TextField(
             controller: verificationCodeController,
             decoration: InputDecoration(
               labelText: 'Enter Verification Code',
               border: OutlineInputBorder(),
             ),
           ),
           SizedBox(height: 20),
           ElevatedButton(
             onPressed: () => _verify(context),
             child: Text('Verify'),
             ),
                 ],
               ),
             ),
           ),
         ),
       ],
     ),
   );
 }
}

