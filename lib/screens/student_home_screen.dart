import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/local_db_service.dart';
import 'settings_screen.dart';
import 'student_calendar_screen.dart';
import 'student_checkin_screen.dart';
import 'tutor_home_screen.dart';
import 'dart:async';

class Session {
  final DateTime startTime;
  final DateTime endTime;
  final String? course;

  Session({
    required this.startTime,
    required this.endTime,
    this.course,
  });
}

class StudentHomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const StudentHomeScreen({required this.user});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  List<Session> upcomingSessions = [];
  bool _isOffline = false;
  String? _firstName;

  @override
  void initState() {
    super.initState();
    // Trigger sync every 5 minutes
    Timer.periodic(Duration(minutes: 5), (timer) async {
      await LocalDBService.syncPendingAttendance();
    });
    _loadUpcomingSessions();
    _loadUserName();
  }


  Future<void> _loadUserName() async {
    final user = await LocalDBService.getUserById(widget.user['panther_id']);
    if (user != null && mounted) {
      final rawName = user['firstname'] ?? '';
      final capitalized = rawName.isNotEmpty // Make sure name is capitalized
          ? rawName[0].toUpperCase() + rawName.substring(1)
          : '';
      if (mounted){
        setState(() {
          _firstName = capitalized;
        });
      }
    }
  }




  Future<bool> isConnected() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  DateTime parseDate(dynamic value) {
    if (value is int) {
      if (value < 10000000000) return DateTime.fromMillisecondsSinceEpoch(value * 1000);
      return DateTime.fromMillisecondsSinceEpoch(value);
    } else if (value is String) {
      return DateTime.parse(value);
    } else {
      throw Exception("Unsupported date format: $value");
    }
  }



Future<void> _loadUpcomingSessions() async {
  final studentId = widget.user['panther_id'];
  final now = DateTime.now();
  final sevenDaysFromNow = now.add(Duration(days: 7));
  List<Map<String, dynamic>> sessions = [];

  final connected = await isConnected();
  bool apiUnavailable = false;

  if (connected) {
    try {
      sessions = await ApiService.getStudentSessions(studentId.toString());

      // Cache online sessions
      await LocalDBService.saveStudentSessions(studentId, sessions);
      _isOffline = false;

      // print("✅ Loaded ${sessions.length} sessions from API");
    } catch (e) {
      print("⚠️ API unavailable or network error: $e");
      apiUnavailable = true;
    }
  }

  if (!connected || apiUnavailable) {
    print("📦 Loading sessions from local DB");
    sessions = await LocalDBService.getStudentSessions(studentId);
    _isOffline = true;
  }

  // Filter for sessions booked by this student within the next 7 days
  final filtered = <Session>[];
  for (var s in sessions) {
    try {
      final start = parseDate(s['start_time']);
      final end = parseDate(s['end_time']);
      final isBooked = s['status'] == 'booked' &&
          s['student'] != null &&
          s['student']['id'].toString() == studentId.toString();

      if (isBooked && start.isAfter(now) && start.isBefore(sevenDaysFromNow)) {
        filtered.add(Session(
          startTime: start,
          endTime: end,
          course: s['course']?.toString(),
        ));
      }
    } catch (e) {
      print("⚠️ Skipping bad session: $s — $e");
    }
  }

  if (mounted) {
    setState(() {
      upcomingSessions = filtered;
    });
  }

  if (_isOffline && mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Offline mode: showing locally stored sessions."),
        backgroundColor: Colors.orange,
      ),
    );
  }
}









  @override
  Widget build(BuildContext context) {
    final roles = (widget.user['roles'] as String).split(',');
    final hasTutorAccess = roles.contains('tutor');
    final pantherId = widget.user['panther_id'];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SmartStart',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SettingsScreen()),
              );
              await _loadUpcomingSessions();
            },
          ),
          if (hasTutorAccess)
            TextButton(
              onPressed: () async {
                await Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TutorHomeScreen(user: widget.user),
                  ),
                );
                await _loadUpcomingSessions();
              },
              child: const Text(
                'Switch to Tutor View',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUpcomingSessions,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    _firstName != null
                        ? "Welcome, $_firstName!"
                        : "Welcome!",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StudentCalendarScreen(studentId: pantherId),
                            ),
                          );
                          await _loadUpcomingSessions();
                        },
                        icon: Icon(Icons.calendar_today),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "Schedule",
                            style: TextStyle(fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StudentCheckinScreen(user: widget.user),
                            ),
                          );
                          await _loadUpcomingSessions();
                        },
                        icon: Icon(Icons.qr_code_scanner),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "Scan Code",
                            style: TextStyle(fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Upcoming Sessions (Next Week):",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                if (upcomingSessions.isNotEmpty)
                  ...upcomingSessions.map((session) {
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: Icon(Icons.access_time),
                        title: Text(
                          DateFormat.MMMd().format(session.startTime),
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        // subtitle: Text(
                        //   '${DateFormat.jm().format(session.startTime)} - ${DateFormat.jm().format(session.endTime)}',
                        // ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (session.course != null && session.course!.isNotEmpty)
                              Text(
                                session.course!,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            Text(
                              '${DateFormat.jm().format(session.startTime)} - ${DateFormat.jm().format(session.endTime)}',
                            ),
                          ],
                        ),


                      
                      ),
                    );
                  }).toList()
                else
                  Text(
                    "No sessions booked in the next 7 days.",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
      ),

    );
  }
}
