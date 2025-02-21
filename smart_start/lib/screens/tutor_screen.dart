import 'package:flutter/material.dart';
import 'schedule_session_screen.dart';
import 'generate_qr_code_screen.dart';
import 'settings_screen.dart';

class TutorScreen extends StatelessWidget {
 @override
 Widget build(BuildContext context) {
   return Scaffold(
     appBar: AppBar(title: Text('Tutor Dashboard')),
     body: Center(
       child: Padding(
         padding: const EdgeInsets.all(16.0),
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             Text(
               'Welcome Tutor!',
               style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
             ),
             SizedBox(height: 30),


             SizedBox(
               width: MediaQuery.of(context).size.width * 0.6,
               child: ElevatedButton(
                 onPressed: () {
                   Navigator.push(
                     context,
                     MaterialPageRoute(builder: (context) => ScheduleSessionScreen()),
                   );
                 },
                 style: ElevatedButton.styleFrom(
                   padding: EdgeInsets.symmetric(vertical: 25, horizontal: 20), // Increased vertical padding
                   textStyle: TextStyle(fontSize: 18),
                   shape: RoundedRectangleBorder(
                     borderRadius: BorderRadius.circular(10.0),
                   ),
                 ),
                 child: Text('Schedule'),
               ),
             ),
             SizedBox(height: 20),


             SizedBox(
               width: MediaQuery.of(context).size.width * 0.6,
               child: ElevatedButton(
                 onPressed: () {
                   Navigator.push(
                     context,
                     MaterialPageRoute(builder: (context) => GenerateQRCodeScreen()),
                   );
                 },
                 style: ElevatedButton.styleFrom(
                   padding: EdgeInsets.symmetric(vertical: 25, horizontal: 20), // Increased vertical padding
                   textStyle: TextStyle(fontSize: 18),
                   shape: RoundedRectangleBorder(
                     borderRadius: BorderRadius.circular(10.0),
                   ),
                 ),
                 child: Text('Generate QR Code'),
               ),
             ),
             SizedBox(height: 20),


             SizedBox(
               width: MediaQuery.of(context).size.width * 0.6,
               child: ElevatedButton(
                 onPressed: () {
                   Navigator.push(
                     context,
                     MaterialPageRoute(builder: (context) => SettingsScreen()),
                   );
                 },
                 style: ElevatedButton.styleFrom(
                   padding: EdgeInsets.symmetric(vertical: 25, horizontal: 20), // Increased vertical padding
                   textStyle: TextStyle(fontSize: 18),
                   shape: RoundedRectangleBorder(
                     borderRadius: BorderRadius.circular(10.0),
                   ),
                 ),
                 child: Text('Settings'),
               ),
             ),
           ],
         ),
       ),
     ),
   );
 }
}
