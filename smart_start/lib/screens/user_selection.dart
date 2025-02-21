import 'package:flutter/material.dart';
import 'login_screen.dart';

class UserSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartStart'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          /// Background watermark with scaling
          Positioned.fill(
            child: Opacity(
              opacity: 0.35, // Adjust opacity for a subtle watermark effect
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
          
          /// Main content (text & buttons)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Welcome',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onBackground, // Matches the rest of the theme
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Are you a Student or a Tutor?',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onBackground, // Matches the rest of the theme
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 70),
                  MediaQuery.of(context).size.width > 600
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.35,
                              height: MediaQuery.of(context).size.height * 0.25,
                              child: _buildButton(context, 'Student'),
                            ),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.35,
                              height: MediaQuery.of(context).size.height * 0.25,
                              child: _buildButton(context, 'Tutor'),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.7,
                              height: MediaQuery.of(context).size.height * 0.18,
                              child: _buildButton(context, 'Student'),
                            ),
                            const SizedBox(height: 50),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.7,
                              height: MediaQuery.of(context).size.height * 0.18,
                              child: _buildButton(context, 'Tutor'),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(BuildContext context, String userType) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen(userType: userType)),
        );
      },
      child: Text(userType),
    );
  }
}
