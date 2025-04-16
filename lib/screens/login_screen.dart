import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/local_db_service.dart';
import 'tutor_home_screen.dart';
import 'student_home_screen.dart';
import 'register_screen.dart';
import 'package:sqflite/sqflite.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String message = '';






  Future<void> handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final db = await LocalDBService.database;

    try {
      // Step 1: Try online login first
      final result = await ApiService.login(email, password);

      if (result['status'] == 'success') {
        final user = result['user'];
        final roles = user['roles'].split(',');

        print("🌐 Server user roles: ${user['roles']}");

        // Save user locally
        await db.insert('user', {
          'panther_id': user['panther_id'],
          'firstname': user['firstName'],
          'lastname': user['lastName'],
          'email': user['email'],
          'password': password,
          'roles': user['roles'],
          'courses': user['courses'] ?? '',
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        // Navigate
        if (roles.contains('tutor')) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => TutorHomeScreen(user: user)),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => StudentHomeScreen(user: user)),
          );
        }
        return;
      } else {
        // If user not found online, delete local entry
        final localUser = await db.query('user', where: 'email = ?', whereArgs: [email]);
        if (localUser.isNotEmpty) {
          await db.delete('user', where: 'email = ?', whereArgs: [email]);
          await db.delete('schedules', where: 'tutor_id = ?', whereArgs: [localUser.first['panther_id']]);
          await db.delete('attendance_pending', where: 'student_id = ?', whereArgs: [localUser.first['panther_id']]);
          print("🧹 Deleted stale local user and related data for $email");
        }
        setState(() => message = result['message'] ?? 'Login failed');
      }
    } catch (e) {
      print("⚠️ Online login failed: $e");

      // Step 2: Fallback to local login
      final localUser = await db.query(
        'user',
        where: 'email = ? AND password = ?',
        whereArgs: [email, password],
      );

      if (localUser.isNotEmpty) {
        final user = localUser.first;
        final roles = (user['roles'] as String? ?? '').split(',');

        print("📦 Local user roles: ${user['roles']}");

        if (roles.contains('tutor')) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => TutorHomeScreen(user: user)),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => StudentHomeScreen(user: user)),
          );
        }
      } else {
        setState(() => message = 'Offline login failed – user not found locally');
      }
    }
  }













  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SmartStart Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(labelText: 'Email'),
                  ),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(labelText: 'Password'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: handleLogin,
                    child: const Text('Login'),
                  ),
                  if (message.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        message,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),

            // 🔗 Register link
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RegisterScreen()),
                );
              },
              child: const Text("No account? Register here"),
            ),
          ],
        ),
      ),
    );
  }
}

































