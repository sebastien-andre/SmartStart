import 'package:flutter/material.dart';


class SettingsScreen extends StatefulWidget {
 @override
 _SettingsScreenState createState() => _SettingsScreenState();
}


class _SettingsScreenState extends State<SettingsScreen> {
 String? selectedOption;


 void _showMessage(String message) {
   ScaffoldMessenger.of(context).showSnackBar(
     SnackBar(content: Text(message)),
   );
 }


 void _showChangePasswordDialog(BuildContext context) {
   TextEditingController currentPasswordController = TextEditingController();
   TextEditingController newPasswordController = TextEditingController();
   TextEditingController confirmPasswordController = TextEditingController();


   showDialog(
     context: context,
     builder: (BuildContext context) {
       return AlertDialog(
         title: Text('Change Password'),
         content: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             TextField(
               controller: currentPasswordController,
               obscureText: true,
               decoration: InputDecoration(labelText: 'Current Password'),
             ),
             TextField(
               controller: newPasswordController,
               obscureText: true,
               decoration: InputDecoration(labelText: 'New Password'),
             ),
             TextField(
               controller: confirmPasswordController,
               obscureText: true,
               decoration: InputDecoration(labelText: 'Confirm New Password'),
             ),
           ],
         ),
         actions: [
           TextButton(
             onPressed: () => Navigator.of(context).pop(),
             child: Text('Cancel'),
           ),
           ElevatedButton(
             onPressed: () {
               String currentPassword = currentPasswordController.text;
               String newPassword = newPasswordController.text;
               String confirmPassword = confirmPasswordController.text;


               if (newPassword.isEmpty || confirmPassword.isEmpty || currentPassword.isEmpty) {
                 _showMessage('All fields are required.');
                 return;
               }


               if (newPassword != confirmPassword) {
                 _showMessage('New passwords do not match.');
                 return;
               }


               // Simulate password change (Replace with API call)
               _showMessage('Password successfully changed!');
               Navigator.of(context).pop();
             },
             child: Text('Change Password'),
           ),
         ],
       );
     },
   );
 }


 void _showChangeEmailDialog(BuildContext context) {
   TextEditingController newEmailController = TextEditingController();


   showDialog(
     context: context,
     builder: (BuildContext context) {
       return AlertDialog(
         title: Text('Change Email'),
         content: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             TextField(
               controller: newEmailController,
               decoration: InputDecoration(labelText: 'New Email'),
             ),
           ],
         ),
         actions: [
           TextButton(
             onPressed: () => Navigator.of(context).pop(),
             child: Text('Cancel'),
           ),
           ElevatedButton(
             onPressed: () {
               String newEmail = newEmailController.text;


               if (newEmail.isEmpty) {
                 _showMessage('Email cannot be empty.');
                 return;
               }


               // Simulate Email change (Replace with API call)
               _showMessage('Email successfully changed!');
               Navigator.of(context).pop();
             },
             child: Text('Change Email'),
           ),
         ],
       );
     },
   );
 }


 @override
 Widget build(BuildContext context) {
   return Scaffold(
     appBar: AppBar(title: Text('SmartStart')),
     body: Center(
       child: Padding(
         padding: EdgeInsets.all(16.0),
         child: SingleChildScrollView(
           child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             crossAxisAlignment: CrossAxisAlignment.center,
             children: [
               Text(
                 'Settings',
                 style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
               ),
               SizedBox(height: 20),


               _buildSettingsTile(
                 title: 'Push Notifications',
                 value: 'Push Notifications',
                 groupValue: selectedOption,
                 onChanged: (value) {
                   setState(() {
                     selectedOption = value;
                   });
                   _showMessage('Push notifications settings coming soon.');
                 },
               ),
               SizedBox(height: 20),


               _buildSettingsTile(
                 title: 'Change Password',
                 value: 'Change Password',
                 groupValue: selectedOption,
                 onChanged: (value) {
                   setState(() {
                     selectedOption = value;
                   });
                   _showChangePasswordDialog(context);
                 },
               ),
               SizedBox(height: 20),


               _buildSettingsTile(
                 title: 'Change Email',
                 value: 'Change Email',
                 groupValue: selectedOption,
                 onChanged: (value) {
                   setState(() {
                     selectedOption = value;
                   });
                   _showChangeEmailDialog(context);
                 },
               ),
             ],
           ),
         ),
       ),
     ),
   );
 }


 Widget _buildSettingsTile({
   required String title,
   required String value,
   required String? groupValue,
   required ValueChanged<String?> onChanged,
 }) {
   return SizedBox(
     width: MediaQuery.of(context).size.width * 0.8,
     child: RadioListTile<String>(
       title: Text(title, style: TextStyle(fontSize: 18)),
       value: value,
       groupValue: groupValue,
       onChanged: onChanged,
       controlAffinity: ListTileControlAffinity.leading,
       contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
     ),
   );
 }
}
