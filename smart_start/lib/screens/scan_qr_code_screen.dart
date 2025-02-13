import 'package:flutter/material.dart';

class ScanQRCodeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Scan QR Code')),
      body: Center(child: Text('Scan your QR code here.')),
    );
  }
}
