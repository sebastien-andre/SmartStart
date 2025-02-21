import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? selectedOption;

  void _showMessage(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      backgroundColor: Color(0xFF001F3F), // Navy Blue Background
      behavior: SnackBarBehavior.floating, // Floating style for better UI
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0), // Rounded corners
      ),
    ),
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
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            'Change Password',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildThemedTextField(currentPasswordController, 'Current Password', obscureText: true),
              _buildThemedTextField(newPasswordController, 'New Password', obscureText: true),
              _buildThemedTextField(confirmPasswordController, 'Confirm New Password', obscureText: true),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: Theme.of(context).textTheme.bodyLarge),
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
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            'Change Email',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: _buildThemedTextField(newEmailController, 'New Email'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: Theme.of(context).textTheme.bodyLarge),
            ),
            ElevatedButton(
              onPressed: () {
                String newEmail = newEmailController.text;

                if (newEmail.isEmpty) {
                  _showMessage('Email cannot be empty.');
                  return;
                }

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

  Widget _buildThemedTextField(TextEditingController controller, String label, {bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
            borderRadius: BorderRadius.circular(10.0),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SmartStart', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
      ),
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
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),

                /// Push Notifications
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

                /// Change Password
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

                /// Change Email
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
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        activeColor: Theme.of(context).colorScheme.primary,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      ),
    );
  }
}