import 'package:flutter/material.dart';

class GenerateQRCodeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Generate QR Code')),
      body: Center(child: Text('Generate your QR code here.')),
    );
  }
}
