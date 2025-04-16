import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import '../services/api_service.dart';
import '../services/local_db_service.dart';

class StudentCheckinScreen extends StatefulWidget {
  final Map<String, dynamic> user; // student info with panther_id

  const StudentCheckinScreen({required this.user});

  @override
  State<StudentCheckinScreen> createState() => _StudentCheckinScreenState();
}

class _StudentCheckinScreenState extends State<StudentCheckinScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String message = '';
  bool scanned = false;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
  this.controller = controller;

  controller.scannedDataStream.listen((scanData) async {
    if (scanned) return;
    scanned = true;

    final sessionId = int.tryParse(scanData.code ?? '');

    if (sessionId == null) {
      setState(() => message = "Invalid QR code.");
      return;
    }

    // Format current time
    final now = DateTime.now().toUtc();
    final timeScanned = DateFormat("yyyy-MM-ddTHH:mm:ss'Z'").format(now);

    try {
      final response = await ApiService.checkInStudent(
        studentId: widget.user['panther_id'],
        sessionId: sessionId,
        timeScanned: timeScanned,
      );

      if (response['status'] == 'success') {
        setState(() {
          message = response['message'] ?? 'Check-in successful';
        });
      } else {
        setState(() {
          message = response['message'] ?? 'Check-in failed';
        });
      }
    } catch (e) {
      print("⚠️ Offline or API failure. Saving locally.");

      // Save to local pending check-in table
      await LocalDBService.savePendingAttendance(
        sessionId: sessionId,
        studentId: widget.user['panther_id'],
        timeScanned: timeScanned,
      );

      setState(() {
        message = "✔️ Check-in saved offline. Will sync when online.";
      });
    }
  });
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("QR Check-in")),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(message, style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
