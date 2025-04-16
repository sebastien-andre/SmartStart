import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/local_db_service.dart';
import 'student_home_screen.dart';
import 'settings_screen.dart';
import 'scheduling_screen.dart';
import 'generate_code_screen.dart';

class TutorHomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const TutorHomeScreen({required this.user});

  @override
  State<TutorHomeScreen> createState() => _TutorHomeScreenState();
}

class _TutorHomeScreenState extends State<TutorHomeScreen> {
  List<Map<String, dynamic>> _sessions = [];
  String? _firstName;
  bool _isOffline = false;
  Map<String, double> _weeklyHoursByCourse = {};


  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadTutorSessions();
  }

  Future<void> _loadUserName() async {
    final user = await LocalDBService.getUserById(widget.user['panther_id']);
    if (user != null && mounted) {
      final rawName = user['firstname'] ?? '';
      final capitalized = rawName.isNotEmpty
          ? rawName[0].toUpperCase() + rawName.substring(1)
          : '';
      setState(() {
        _firstName = capitalized;
      });
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

  Future<void> _loadTutorSessions() async {
    final tutorId = widget.user['panther_id'];
    final now = DateTime.now();
    final weekFromNow = now.add(Duration(days: 7));
    List<Map<String, dynamic>> sessions = [];

    final connected = await isConnected();
    bool apiDown = false;

    if (connected) {
      try {
        // 🔁 Online method (see note below)
        final onlineSessions = await ApiService.getTutorSessions(tutorId.toString());
        await LocalDBService.saveTutorSessions(tutorId, onlineSessions);
        sessions = onlineSessions;
        _isOffline = false;
      } catch (e) {
        print("⚠️ API error: $e");
        apiDown = true;
      }
    }

    if (!connected || apiDown) {
      sessions = await LocalDBService.getTutorSessions(tutorId);
      _isOffline = true;
    }

    sessions = sessions.where((s) {
      try {
        final start = parseDate(s['start_time']);
        return start.isAfter(now) && start.isBefore(weekFromNow);
      } catch (_) {
        return false;
      }
    }).toList();

    // setState(() {
    //   _sessions = sessions;
    // });

    final Map<String, double> hoursPerCourse = {};

    for (var session in sessions) {
      try {
        final start = parseDate(session['start_time']);
        final end = parseDate(session['end_time']);
        final duration = end.difference(start).inMinutes / 60.0;
        final course = session['course']?.toString() ?? 'Unknown';

        hoursPerCourse[course] = (hoursPerCourse[course] ?? 0) + duration;
      } catch (_) {}
    }

    setState(() {
      _sessions = sessions;
      _weeklyHoursByCourse = hoursPerCourse;
    });

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
    final hasStudentAccess = true;

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
              await _loadTutorSessions();
            },
          ),
            TextButton(
              onPressed: () async {
                await Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StudentHomeScreen(user: widget.user),
                  ),
                );
              },
              child: const Text(
                'Switch to Student View',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
        ],
      ),
    
      body: RefreshIndicator(
        onRefresh: _loadTutorSessions,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    _firstName != null ? "Welcome, $_firstName!" : "Welcome!",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 30),
                

                if (_weeklyHoursByCourse.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Weekly Hours by Subject",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      child: Column(
                        children: _weeklyHoursByCourse.entries.map((entry) {
                          final hours = entry.value;
                          final isOverLimit = hours > 10;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    entry.key,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Text(
                                  "${hours.toStringAsFixed(1)} hrs",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isOverLimit ? Colors.red : Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],

 
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ScheduleSessionScreen(tutorId: pantherId.toString()),
                            ),
                          );
                          await _loadTutorSessions();
                        },
                        icon: Icon(Icons.calendar_today),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text("Schedule", style: TextStyle(fontSize: 16)),
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
                              builder: (_) => GenerateCodeScreen(),
                            ),
                          );
                          await _loadTutorSessions();
                        },
                        icon: Icon(Icons.qr_code),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text("Show Code", style: TextStyle(fontSize: 16)),
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
                if (_sessions.isNotEmpty)
                  ..._sessions.map((session) {
                    final start = parseDate(session['start_time']);
                    final end = parseDate(session['end_time']);
                    final isBooked = session['status'] == 'booked';

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: Icon(Icons.access_time),
                        title: Text(
                          DateFormat.MMMd().format(start),
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        // subtitle: Text(
                        //   '${DateFormat.jm().format(start)} - ${DateFormat.jm().format(end)}',
                        // ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (session['course'] != null && session['course'].toString().isNotEmpty)
                              Text(
                                session['course'],
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            Text(
                              '${DateFormat.jm().format(start)} - ${DateFormat.jm().format(end)}',
                            ),
                          ],
                        ),

                        trailing: isBooked
                            ? Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade600,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "Booked",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    );
                  }).toList()
                else
                  Text(
                    "No sessions scheduled in the next 7 days.",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
      )
    );
  }
}
