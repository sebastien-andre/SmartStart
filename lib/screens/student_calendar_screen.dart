import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/api_service.dart';
import '../services/local_db_service.dart';
import 'dart:io';
import 'dart:async';

class StudentCalendarScreen extends StatefulWidget {
  final int studentId;

  const StudentCalendarScreen({required this.studentId});

  @override
  _StudentCalendarScreenState createState() => _StudentCalendarScreenState();
}

class _StudentCalendarScreenState extends State<StudentCalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String? _selectedCourse;
  List<String> _availableCourses = [];

  

  List<Map<String, dynamic>> _sessions = [];
  List<int> _bookedSessionIds = [];
  Map<DateTime, List<Map<String, dynamic>>> _sessionsByDay = {};

  @override
  void initState() {
    super.initState();
    // Trigger sync every 5 minutes
    Timer.periodic(Duration(minutes: 5), (timer) async {
      await LocalDBService.syncPendingAttendance();
    });

    fetchSessions();
  }

  Future<bool> isConnected() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }








Future<void> fetchSessions() async {
  final connected = await isConnected();
  List<Map<String, dynamic>> sessions = [];

  bool apiUnavailable = false;

  if (connected) {
    try {
      sessions = await ApiService.getStudentSessions(widget.studentId.toString());

      // Save to local db only if API call succeeded
      await LocalDBService.saveStudentSessions(widget.studentId, sessions);
    } catch (e) {
      // Only triggered if the API server is unreachable or connection refused
      print("⚠️ API unavailable or network refused: $e");
      apiUnavailable = true;
    }
  }

  if (!connected || apiUnavailable) {
    print("📦 Loading sessions from local DB");
    sessions = await LocalDBService.getStudentSessions(widget.studentId);
  }

  try {
    // Update booked session IDs and full session list
    final booked = <int>[];
    for (var s in sessions) {
      if (s['status'] == 'booked' &&
          s.containsKey('student') &&
          s['student'] != null &&
          s['student']['id'].toString() == widget.studentId.toString()) {
        booked.add(s['session_id']);
      }
    }

    // setState(() {
    //   _sessions = sessions;
    //   _bookedSessionIds = booked;
    // });
    final courseSet = <String>{};
    for (var s in sessions) {
      if (s.containsKey('course') && s['course'] != null) {
        courseSet.add(s['course'].toString());
      }
    }

    setState(() {
      _sessions = sessions;
      _bookedSessionIds = booked;
      _availableCourses = courseSet.toList()..sort();
      if (_selectedCourse != null && !_availableCourses.contains(_selectedCourse)) {
        _selectedCourse = null; 
      }
    });

    _groupSessionsByDay();


    _groupSessionsByDay();
  } catch (e) {
    print('❌ Error processing session data: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('❌ Failed to load sessions')),
    );
  }
}














  // void _groupSessionsByDay() {
  //   _sessionsByDay.clear();
  //   for (var session in _sessions) {
  //     final start = DateTime.parse(session['start_time']);
  //     final key = DateTime(start.year, start.month, start.day);
  //     _sessionsByDay.putIfAbsent(key, () => []).add(session);
  //   }
  // }

  
  void _groupSessionsByDay() {
    _sessionsByDay.clear();
    for (var session in _sessions) {
      if (_selectedCourse != null && session['course'] != _selectedCourse) continue;

      final start = DateTime.parse(session['start_time']);
      final key = DateTime(start.year, start.month, start.day);
      _sessionsByDay.putIfAbsent(key, () => []).add(session);
    }
  }




  Future<void> _bookSession(int sessionId) async {
    final response = await ApiService.bookSession(
      studentId: widget.studentId,
      sessionId: sessionId,
    );

    if (response['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Session booked")),
      );
      await fetchSessions(); // refresh
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ ${response['message']}")),
      );
    }
  }


  Future<void> _unbookSession(int sessionId) async {
    final response = await ApiService.unbookSession(
      studentId: widget.studentId,
      sessionId: sessionId,
    );

    if (response['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("🗑️ Session unbooked")),
      );
      await fetchSessions(); // Refresh calendar view
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ ${response['message']}")),
      );
    }
  }










Widget _buildSessionListForDay(DateTime day) {
  final key = DateTime(day.year, day.month, day.day);
  final sessions = _sessionsByDay[key] ?? [];

  if (sessions.isEmpty) {
    return Center(child: Text("No sessions available for this day"));
  }

  return ListView.builder(
    itemCount: sessions.length,
    itemBuilder: (context, index) {
      final session = sessions[index];
      final start = DateTime.parse(session['start_time']);
      final end = DateTime.parse(session['end_time']);
      final sessionId = session['session_id'];
      final status = session['status'];
      final isBookedByThisStudent = _bookedSessionIds.contains(sessionId);

      return ListTile(
        leading: Icon(Icons.schedule),
        title: Text("${start.hour}:00 - ${end.hour}:00"),
        // subtitle: Text("Status: ${isBookedByThisStudent ? 'Booked' : status}"),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (session['course'] != null && session['course'].toString().isNotEmpty)
              Text(
                session['course'],
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            Text("Status: ${isBookedByThisStudent ? 'Booked' : status}"),
          ],
        ),

        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isBookedByThisStudent && status == 'available')
              ElevatedButton(
                onPressed: () => _bookSession(sessionId),
                child: Text("Book"),
              ),
            if (isBookedByThisStudent)
              OutlinedButton(
                onPressed: () => _unbookSession(sessionId),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: Text("Unbook"),
              ),
          ],
        ),
      );
    },
  );
}









  Widget _buildMarkedDay(DateTime day, Color color) {
  return Container(
    margin: const EdgeInsets.all(6.0),
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
    ),
    alignment: Alignment.center,
    child: Text(
      '${day.day}',
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
  );
}


  @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: Text("Student Calendar")),
        body: Column(
          children: [
            if (_availableCourses.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Text("Filter by course:"),
                    SizedBox(width: 10),
                    DropdownButton<String>(
                      value: _selectedCourse,
                      hint: Text("All"),
                      items: [
                        DropdownMenuItem(value: null, child: Text("All")),
                        ..._availableCourses.map((course) => DropdownMenuItem(
                              value: course,
                              child: Text(course),
                            )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCourse = value;
                          _groupSessionsByDay(); // update calendar marks
                        });
                      },
                    ),
                  ],
                ),
              ),

            TableCalendar(
              firstDay: DateTime.utc(2024, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              calendarFormat: _calendarFormat,
              onFormatChanged: (format) {
                setState(() => _calendarFormat = format);
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              calendarBuilders: CalendarBuilders(

                defaultBuilder: (context, day, _) {
                  final key = DateTime(day.year, day.month, day.day);
                  final sessions = _sessionsByDay[key];

                  if (sessions != null && sessions.isNotEmpty) {
                    final hasBooked = sessions.any((s) => s['status'] == 'booked');
                    return _buildMarkedDay(
                      day,
                      hasBooked ? Colors.green : Colors.grey.shade700,
                    );
                  }
                  return null;
                },



                todayBuilder: (context, day, _) {
                  final key = DateTime(day.year, day.month, day.day);
                  final sessions = _sessionsByDay[key];
                  final hasAvailable = sessions?.any((s) => s['status'] == 'available') ?? false;
                  final color = hasAvailable ? Colors.grey.shade700 : Colors.blue;

                  return _buildMarkedDay(day, color.withOpacity(0.7));
                },
              ),
            ),
            const SizedBox(height: 8),

            // ✅ Add this section below the calendar
            Expanded(
              child: _selectedDay != null
                  ? _buildSessionListForDay(_selectedDay!)
                  : Center(child: Text("Select a date to view sessions")),
            ),
          ],
        ),
      );
    }
    
}
