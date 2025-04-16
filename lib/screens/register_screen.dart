

import 'package:flutter/material.dart';
import 'verification_screen.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController coursesController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  String _selectedRole = 'student';
    final List<String> _availableTopics = [
    'Math',
    'Physics',
    'Computer Science',
    'Chemistry',
    'Biology'
  ];
  final Set<String> _selectedTopics = {};




    Future<void> _register(BuildContext context) async {
      final firstName = firstNameController.text.trim();
      final lastName = lastNameController.text.trim();   
      final email = emailController.text.trim();
      final password = passwordController.text.trim();
      final pantherId = idController.text.trim();

      final courses = _selectedRole == 'tutor'
          ? _selectedTopics.join(',')
          : null;

      if (firstName.isEmpty || lastName.isEmpty || email.isEmpty || password.isEmpty || pantherId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please fill in all fields")),
        );
        return;
      }

      final String roleType = _selectedRole == 'tutor' ? 'tutor' : 'student';

      try {
        final response = await ApiService.sendVerification(email, roleType);

        if (response['status'] == 'success') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerificationScreen(
                id: pantherId,
                firstName: firstName,
                lastName: lastName,
                email: email,
                password: password,
                type: roleType,
                courses: courses,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("❌ ${response['message']}")),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Network error: $e")),
        );
      }
    }










  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.35,
              child: Transform.scale(
                scale: 3.0,
                child: Center(
                  child: Image.asset(
                    'assets/images/water_mark_logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, _, __) => Text('Watermark Not Found'),
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
                  children: [
                    Text("Register", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    SizedBox(height: 20),

                    // Panther ID
                    TextField(
                      controller: idController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Panther ID',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 20),


                    // First Name
                    TextField(
                      controller: firstNameController,
                      decoration: InputDecoration(
                        labelText: 'First Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Last Name
                    TextField(
                      controller: lastNameController,
                      decoration: InputDecoration(
                        labelText: 'Last Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 20),


                    // Email
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'GSU Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Password
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 20),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Register as:"),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                title: Text("Student"),
                                value: "student",
                                groupValue: _selectedRole,
                                onChanged: (value) => setState(() => _selectedRole = value!),
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: Text("Tutor"),
                                value: "tutor",
                                groupValue: _selectedRole,
                                onChanged: (value) => setState(() => _selectedRole = value!),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),



                    if (_selectedRole == 'tutor') ...[
                      SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Select topics you will teach:"),
                      ),
                      Wrap(
                        spacing: 10,
                        children: _availableTopics.map((topic) {
                          return FilterChip(
                            label: Text(topic),
                            selected: _selectedTopics.contains(topic),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  _selectedTopics.add(topic);
                                } else {
                                  _selectedTopics.remove(topic);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],

                    

                    SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: () => _register(context),
                      child: Text("Send Verification"),
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
