import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/api_service.dart';
import '../services/local_db_service.dart';
import 'dart:io';


enum Recurrence { none, weekly, biweekly }

class ScheduleSessionScreen extends StatefulWidget {
  final String tutorId;
  

  const ScheduleSessionScreen({required this.tutorId});

  @override
  _ScheduleSessionScreenState createState() => _ScheduleSessionScreenState();
}



class _ScheduleSessionScreenState extends State<ScheduleSessionScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Recurrence selectedRecurrence = Recurrence.none;


  final TextEditingController _repeatCountController = TextEditingController(text: "1");


  List<TimeSlot> availableTimeSlots = [];
  List<TimeSlot> selectedTimeSlots = [];

  List<Map<String, dynamic>> _sessions = [];
  Map<DateTime, List<Map<String, dynamic>>> _sessionsByDay = {};


  List<String> _courseOptions = [];
  String? _selectedCourse;

  
  @override
  void initState() {
    super.initState();
    for (int hour = 9; hour < 18; hour++) {
      availableTimeSlots.add(TimeSlot(startHour: hour, endHour: hour + 1));
    }
    loadSessions();
    _loadTutorCourses();
  }


  @override
  void dispose() {
    _repeatCountController.dispose(); 
    super.dispose();
  }

  Future<bool> isConnected() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }


  Future<void> loadSessions() async {
    final tutorId = int.tryParse(widget.tutorId) ?? 0;
    List<Map<String, dynamic>> sessions = [];
    final connected = await isConnected();
    bool apiDown = false;

    if (connected) {
      try {
        final onlineSessions = await ApiService.getTutorSessions(widget.tutorId);
        await LocalDBService.saveTutorSessions(tutorId, onlineSessions);
        sessions = onlineSessions;
      } catch (e) {
        print("⚠️ API failed: $e");
        apiDown = true;
      }
    }

    if (!connected || apiDown) {
      print("📦 Loading from local DB");
      sessions = await LocalDBService.getTutorSessions(tutorId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Offline mode: showing locally stored sessions.")),
      );
    }

    setState(() {
      _sessions = sessions;
      _groupSessionsByDay();
    });

    _groupSessionsByDay();
  }




    void _groupSessionsByDay() {
      _sessionsByDay.clear();
      for (var session in _sessions) {
        DateTime start = DateTime.parse(session["start_time"]);
        DateTime dayKey = DateTime(start.year, start.month, start.day);
        _sessionsByDay.putIfAbsent(dayKey, () => []).add(session);
      }
    }

    Widget buildTimeSlotButton(TimeSlot slot) {
      bool isSelected = selectedTimeSlots.contains(slot);
      return GestureDetector(
        onTap: () {
          setState(() {
            isSelected ? selectedTimeSlots.remove(slot) : selectedTimeSlots.add(slot);
          });
        },
        child: Container(
          margin: EdgeInsets.all(4),
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              slot.formatLabel(),
              style: TextStyle(color: isSelected ? Colors.white : Colors.black),
            ),
          ),
        ),
      );
    }



      Future<void> scheduleSessions() async {
        if (_selectedDay == null || selectedTimeSlots.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Select a date and time slots.")),
          );
          return;
        }
        if (_selectedDay!.isBefore(DateTime.now())) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("❌ Cannot schedule sessions in the past.")),
          );
          return;
        }


        if (_selectedCourse == null || _selectedCourse!.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Please select a course for the session.")),
          );
          return;
        }

        
        final online = await isConnected();

        if (!online) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("⚠️ No internet connection. Cannot schedule sessions.")),
          );
          return;
        }

        int repeatCount = int.tryParse(_repeatCountController.text.trim()) ?? 1;
        final recurrenceStr = selectedRecurrence.name;

        int successful = 0; 

        for (var slot in selectedTimeSlots) {
          final start = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day, slot.startHour);
          final end = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day, slot.endHour);

          try {
              final response = await ApiService.scheduleSession(
              tutorId: widget.tutorId,
              startTime: start,
              endTime: end,
              recurrence: recurrenceStr,
              repeatTimes: repeatCount,
              course: _selectedCourse!,
            );


            final int added = response['added'] is int ? response['added'] : 0;

            if (response['status'] == 'success' && added > 0) {
              successful += 1;
              print("✅ Session scheduled: $start to $end");
              await loadSessions();
              } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("⚠️ ${response['message'] ?? 'Scheduling failed.'}")),
          );
        }

      } catch (e) {
        print("❌ API scheduling failed: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Failed to schedule session. Please try again when online.")),
        );
      }
    }

    selectedTimeSlots.clear();

    // Sync after success
    if (successful > 0) {
      try {
        final freshSessions = await ApiService.getTutorSessions(widget.tutorId);
        await LocalDBService.saveTutorSessions(
          int.tryParse(widget.tutorId) ?? 0,
          List<Map<String, dynamic>>.from(freshSessions),
        );

        setState(() {
          _sessions = List<Map<String, dynamic>>.from(freshSessions);
        });
        _groupSessionsByDay();

        await loadSessions();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Sessions scheduled.")),
        );
      } catch (e) {
        print("⚠️ Failed to sync with server after scheduling: $e");
      }
    }
  }



















  Future<void> _unscheduleSession(Map<String, dynamic> session) async {
    final sessionId = session['session_id'] ?? session['id'];
    final startTime = DateTime.parse(session['start_time']);
    final now = DateTime.now();

    if (startTime.difference(now).inHours <= 48) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Cannot unschedule within 48 hours of start time.")),
      );
      return;
    }

    try {
      await ApiService.deleteSession(
        tutorId: widget.tutorId,
        sessions: [
          {
            'start_time': session['start_time'],
            'end_time': session['end_time'],
          }
        ],
      );

      // Refresh
      await loadSessions();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("🗑️ Session unscheduled.")),
      );
    } catch (e) {
      print("❌ Unschedule failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Unable to unschedule. Are you online?")),
      );
    }
  }




  

    Future<void> _loadTutorCourses() async {
      final tutorId = int.tryParse(widget.tutorId);
      final user = await LocalDBService.getUserById(tutorId ?? 0);
      if (user != null && user['courses'] != null) {
        final raw = user['courses'] as String;
        setState(() {
          _courseOptions = raw.split(',').map((e) => e.trim()).toList();
          if (_courseOptions.isNotEmpty) {
            _selectedCourse = _courseOptions.first;
          }
        });
      }
    }






  Widget buildSessionListForSelectedDay() {
    if (_selectedDay == null) return Container();

    final key = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    final sessions = _sessionsByDay[key] ?? [];

    if (sessions.isEmpty) return Padding(padding: EdgeInsets.all(8.0), child: Text("No sessions."));

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: sessions.length,
      itemBuilder: (_, i) {
        final s = sessions[i];
        final start = DateTime.parse(s["start_time"]);
        final end = DateTime.parse(s["end_time"]);
        return ListTile(
          leading: Icon(Icons.event_available, color: Colors.green),
          title: Text("${start.hour}:00 - ${end.hour}:00"),
          // subtitle: Text("Status: ${s["status"] ?? 'unknown'}"),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (s["course"] != null && s["course"].toString().isNotEmpty)
                Text(
                  s["course"],
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              Text("Status: ${s["status"] ?? 'unknown'}"),
            ],
          ),

          //  trailing: (start.difference(DateTime.now()).inHours > 48)
          trailing: start.isAfter(DateTime.now()) && start.difference(DateTime.now()).inHours > 48

            ? OutlinedButton(
                onPressed: () => _unscheduleSession(s),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                child: Text("Unschedule"),
            )
            : null,
          
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Schedule a Session')),
        body: RefreshIndicator(
          onRefresh: loadSessions,
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    TableCalendar(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      calendarFormat: _calendarFormat,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      onDaySelected: (day, focused) {
                        setState(() {
                          _selectedDay = day;
                          _focusedDay = focused;
                        });
                      },
                      onFormatChanged: (format) => setState(() => _calendarFormat = format),
                      onPageChanged: (focused) => _focusedDay = focused,
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, _) {
                          if (_sessionsByDay.containsKey(DateTime(day.year, day.month, day.day))) {
                            return _buildMarkedDay(day, Colors.green.withOpacity(0.5));
                          }
                          return null;
                        },
                        todayBuilder: (context, day, _) {
                          return _buildMarkedDay(
                              day,
                              _sessionsByDay.containsKey(DateTime(day.year, day.month, day.day))
                                  ? Colors.green.withOpacity(0.5)
                                  : Colors.blue.withOpacity(0.3));
                        },
                      ),
                      calendarStyle: CalendarStyle(
                        selectedDecoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                        todayDecoration: BoxDecoration(color: Colors.blue.withOpacity(0.3), shape: BoxShape.circle),
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonTextStyle: TextStyle(color: Colors.white),
                        formatButtonDecoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(8.0)),
                      ),
                    ),
                    SizedBox(height: 20),
                    if (_selectedDay != null)
                      Text("Selected Date: ${_selectedDay!.toLocal()}".split(' ')[0],
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 20),
                    Text("Select Time Slots", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      children: availableTimeSlots.map(buildTimeSlotButton).toList(),
                    ),
                    SizedBox(height: 20),



                    if (_courseOptions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Course: "),
                            DropdownButton<String>(
                              value: _selectedCourse,
                              items: _courseOptions.map((course) {
                                return DropdownMenuItem<String>(
                                  value: course,
                                  child: Text(course),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCourse = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Recurring: "),
                            DropdownButton<Recurrence>(
                              value: selectedRecurrence,
                              items: [
                                DropdownMenuItem(child: Text("None"), value: Recurrence.none),
                                DropdownMenuItem(child: Text("Weekly"), value: Recurrence.weekly),
                                DropdownMenuItem(child: Text("Biweekly"), value: Recurrence.biweekly),
                              ],
                              onChanged: (value) => setState(() => selectedRecurrence = value ?? Recurrence.none),
                            ),
                          ],
                        ),
                        if (selectedRecurrence != Recurrence.none)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: TextField(
                              controller: _repeatCountController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: "Number of repetitions",
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                      ],
                    ),



                    SizedBox(height: 20),
                    ElevatedButton(onPressed: scheduleSessions, child: Text("Schedule Session")),
                    SizedBox(height: 20),
                    if (_selectedDay != null) ...[
                      Text("Sessions for selected day:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      buildSessionListForSelectedDay(),
                    ]
                  ],
              ),
          ),
    )
    );
  }

  Widget _buildMarkedDay(DateTime day, Color color) {
    return Container(
      margin: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(child: Text(day.day.toString(), style: TextStyle(color: Colors.white))),
    );
  }
}

class TimeSlot {
  final int startHour;
  final int endHour;

  TimeSlot({required this.startHour, required this.endHour});

  String formatLabel() {
    return "${_formatHour(startHour)}-${_formatHour(endHour)}";
  }

  String _formatHour(int hour) {
    final period = hour >= 12 ? "pm" : "am";
    int displayHour = hour > 12 ? hour - 12 : hour;
    return "$displayHour$period";
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is TimeSlot && other.startHour == startHour && other.endHour == endHour);

  @override
  int get hashCode => startHour.hashCode ^ endHour.hashCode;
}

















