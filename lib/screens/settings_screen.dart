import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _minutesBefore = 10;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _minutesBefore = prefs.getInt('minutes_before_notification') ?? 10;
    });
  }

  Future<void> _updateNotificationPreference(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('minutes_before_notification', value);
    setState(() {
      _minutesBefore = value;
    });
  }

  void _openNotificationSettings() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Push Notification Settings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Text('Notify me before each session:'),
                  Spacer(),
                  DropdownButton<int>(
                    value: _minutesBefore,
                    items: [5, 10, 15, 30, 60].map((value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text('$value min'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _updateNotificationPreference(value);
                        Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                '(You’ll be reminded this many minutes before your session)',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: Text('Push Notification Settings'),
            subtitle: Text('$_minutesBefore minutes before each session'),
            trailing: Icon(Icons.chevron_right),
            onTap: _openNotificationSettings,
          ),
          // Add more settings options here as needed
        ],
      ),
    );
  }
}
