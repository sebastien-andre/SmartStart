import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class ScheduleSessionScreen extends StatefulWidget {
 @override
 _ScheduleSessionScreenState createState() => _ScheduleSessionScreenState();
}


class _ScheduleSessionScreenState extends State<ScheduleSessionScreen> {
 CalendarFormat _calendarFormat = CalendarFormat.month;
 DateTime _focusedDay = DateTime.now();
 DateTime? _selectedDay;


 @override
 Widget build(BuildContext context) {
   return Scaffold(
     appBar: AppBar(title: Text('Schedule a Session')),
     body: Column(
       children: [
         TableCalendar(
           firstDay: DateTime.utc(2020, 1, 1),
           lastDay: DateTime.utc(2030, 12, 31),
           focusedDay: _focusedDay,
           calendarFormat: _calendarFormat,
           selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
           onDaySelected: (selectedDay, focusedDay) {
             setState(() {
               _selectedDay = selectedDay;
               _focusedDay = focusedDay;
             });
             print("Selected Day: $_selectedDay");
           },
           onFormatChanged: (format) {
             setState(() {
               _calendarFormat = format;
             });
           },
           onPageChanged: (focusedDay) {
             _focusedDay = focusedDay;
           },
           calendarStyle: CalendarStyle(
             selectedDecoration: BoxDecoration(
               color: Colors.blue,
               shape: BoxShape.circle,
             ),
             todayDecoration: BoxDecoration(
               color: Colors.blue.withOpacity(0.3),
               shape: BoxShape.circle,
             ),
           ),
           headerStyle: HeaderStyle(
             formatButtonTextStyle: TextStyle(color: Colors.white),
             formatButtonDecoration: BoxDecoration(
               color: Colors.blue,
               borderRadius: BorderRadius.circular(8.0),
             ),
           ),
         ),
         SizedBox(height: 20),
         if (_selectedDay != null)
           Center(
             child: Text(
               "Selected Date: ${_selectedDay!.toLocal()}".split(' ')[0],
               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
             ),
           ),
       ],
     ),
   );
 }
}
