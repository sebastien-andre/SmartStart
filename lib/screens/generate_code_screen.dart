// import 'package:flutter/material.dart';
// import 'package:qr_flutter/qr_flutter.dart';

// class GenerateCodeScreen extends StatelessWidget {
//   final int tutorId;

//   const GenerateCodeScreen({required this.tutorId});

//   @override
//   Widget build(BuildContext context) {
//     final String qrData = tutorId.toString();

//     return Scaffold(
//       appBar: AppBar(title: Text("Generate Check-In Code")),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                 "Show this QR code to students for attendance check-in.",
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 16),
//               ),
//               const SizedBox(height: 20),
//               QrImageView(
//                 data: qrData,
//                 version: QrVersions.auto,
//                 size: 240.0,
//               ),
//               const SizedBox(height: 20),

//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }




import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/local_db_service.dart';

class GenerateCodeScreen extends StatefulWidget {
  const GenerateCodeScreen({super.key});

  @override
  State<GenerateCodeScreen> createState() => _GenerateCodeScreenState();
}

class _GenerateCodeScreenState extends State<GenerateCodeScreen> {
  int? _sessionId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentSessionId();
  }

  Future<void> _loadCurrentSessionId() async {
    final session = await LocalDBService.getSessionForCurrentTimeslot();
    if (mounted) {
      setState(() {
        _sessionId = session?['id'];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Generate Check-In Code")),
      body: Center(
        child: _loading
            ? CircularProgressIndicator()
            : _sessionId != null
                ? Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Show this QR code to students for attendance check-in.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                        QrImageView(
                          data: _sessionId.toString(),
                          version: QrVersions.auto,
                          size: 240.0,
                        ),
                      ],
                    ),
                  )
                : Text(
                    "No active session at this time.",
                    style: TextStyle(fontSize: 16, color: Colors.red),
                  ),
      ),
    );
  }
}