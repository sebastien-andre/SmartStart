import 'package:flutter/material.dart';
import 'verification_screen.dart';

class RegisterScreen extends StatelessWidget {
 final TextEditingController emailController = TextEditingController();
 final TextEditingController passwordController = TextEditingController();


 void _register(BuildContext context) {
   String email = emailController.text;


   // Show a snack bar confirming registration and navigate to the verification screen
   ScaffoldMessenger.of(context).showSnackBar(
     SnackBar(content: Text('A verification code has been sent to $email')),
   );


   Navigator.push(
     context,
     MaterialPageRoute(builder: (context) => VerificationScreen(email: email)),
   );
 }


 @override


 Widget build(BuildContext context) {
   return Scaffold(
     appBar: AppBar(title: Text('SmartStart')),
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
               Text( // Register Text
                 'Register',
                 style: TextStyle(
                   fontSize: 24,
                   fontWeight: FontWeight.bold,
                 ),
               ),
               SizedBox(height: 20),
               SizedBox( // Email TextField
                 width: MediaQuery.of(context).size.width * 0.8,
                 child: TextField(
                   controller: emailController,
                   decoration: InputDecoration(
                     labelText: 'GSU Email',
                     border: OutlineInputBorder(),
                   ),
                 ),
               ),
               SizedBox(height: 20),
               SizedBox( // Password TextField
                 width: MediaQuery.of(context).size.width * 0.8,
                 child: TextField(
                   controller: passwordController,
                   obscureText: true,
                   decoration: InputDecoration(
                     labelText: 'Password',
                     border: OutlineInputBorder(),
                   ),
                 ),
               ),
               SizedBox(height: 20),
               SizedBox( // Register Button
                 width: MediaQuery.of(context).size.width * 0.8,
                 child: ElevatedButton(
                   onPressed: () => _register(context),
                   style: ElevatedButton.styleFrom(
                     padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                     textStyle: TextStyle(fontSize: 18),
                   ),
                   child: Text('Register'),
                 ),
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
