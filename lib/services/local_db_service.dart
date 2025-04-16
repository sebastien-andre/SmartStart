import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'api_service.dart';

class LocalDBService {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await initDB();
    return _db!;
  }









  static Future<Database> initDB() async {
    final path = join(await getDatabasesPath(), 'smartstart_offline.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute("""
          CREATE TABLE user (
            panther_id INTEGER PRIMARY KEY,
            firstname TEXT NOT NULL,
            lastname TEXT NOT NULL,
            email TEXT NOT NULL,
            password TEXT NOT NULL,
            roles TEXT NOT NULL,
            courses TEXT
          );
        """);

        await db.execute("""
          CREATE TABLE schedules (
            id INTEGER PRIMARY KEY,
            tutor_id INTEGER,
            student_id INTEGER,
            start_time TEXT NOT NULL,
            end_time TEXT NOT NULL,
            status TEXT,
            course TEXT
          );
        """);

        await db.execute("""
          CREATE TABLE attendance_pending (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            schedule_id INTEGER NOT NULL,
            student_id INTEGER NOT NULL,
            time_scanned TEXT NOT NULL
          );
        """);
      },
      
    );


    
  }



  /// 🔧 Initialize the local DB for use in main()
  static Future<void> init() async {
    _db = await initDB();
  }


  




  static Future<void> clearSessions() async {
    final db = await database;
    await db.delete('schedules');
  }





  static Future<List<Map<String, dynamic>>> getSessionsForTutor(String tutorId) async {
    final db = await database;
    return await db.query(
      'schedules',
      where: 'student_id = ?', 
      whereArgs: [int.tryParse(tutorId)],
    );
  }





  // static Future<void> saveSession({
  //   required String tutorId,
  //   required String startTime,
  //   required String endTime,
  //   required String course,
  //   required String recurrence
  // }) async {
  //   final db = await database;
  //   await db.insert('schedules', {
  //     'id': DateTime.now().millisecondsSinceEpoch, // temporary local ID
  //     'tutor_id': int.tryParse(tutorId),
  //     'start_time': startTime,
  //     'end_time': endTime,
  //     'status': 'available',
  //     'course': course
  //   });
  // }









  static Future<void> saveSessions(List<Map<String, dynamic>> sessions) async {
    final db = await database;
    final batch = db.batch();
    
    for (final session in sessions) {
      final localSession = Map<String, dynamic>.from(session);

      // Rename 'session_id' to 'id'
      if (localSession.containsKey('session_id')) {
        localSession['id'] = localSession.remove('session_id');
      }

      // Normalize start_time and end_time to ISO strings
      final start = localSession['start_time'];
      final end = localSession['end_time'];

      localSession['start_time'] = (start is int)
          ? DateTime.fromMillisecondsSinceEpoch(start).toIso8601String()
          : start.toString();

      localSession['end_time'] = (end is int)
          ? DateTime.fromMillisecondsSinceEpoch(end).toIso8601String()
          : end.toString();

      // Extract and assign student_id if it's nested inside a student map
      if (localSession.containsKey('student')) {
        final student = localSession.remove('student');
        if (student is Map<String, dynamic> && student.containsKey('id')) {
          localSession['student_id'] = student['id'];
        }
      }

      batch.insert('schedules', localSession, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  } 












// Student-specific session retrieval


static Future<void> saveStudentSessions(int studentId, List<Map<String, dynamic>> sessions) async {
    final db = await database;

    // Clear existing entries related to this student (optional but recommended)
    await db.delete('schedules', where: 'student_id = ? OR status = ?', whereArgs: [studentId, 'available']);

    // Insert fresh data
    final batch = db.batch();

    for (var session in sessions) {
      final int id = session['session_id'];
      final int tutorId = session['tutor_id'];
      final String startTime = session['start_time'];
      final String endTime = session['end_time'];
      final String status = session['status'];
      final String course = session['course'];

      int? student;
      if (status == 'booked' && session['student'] != null) {
        final s = session['student'];
        if (s is Map && s['id'] != null) {
          student = int.tryParse(s['id'].toString());
        }
      }

      batch.insert(
        'schedules',
        {
          'id': id,
          'tutor_id': tutorId,
          'student_id': student,
          'start_time': startTime,
          'end_time': endTime,
          'status': status,
          'course': course
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }






























  static Future<List<Map<String, dynamic>>> getStudentSessions(int studentId) async {
    final db = await database;

  final result = await db.query(
      'schedules',
      where: 'student_id = ? OR status = ?',
      whereArgs: [studentId, 'available'],
      orderBy: 'start_time ASC',
    );

    // Reconstruct sessions with optional student object for booked sessions
    return result.map((row) {
      final session = {
        'session_id': row['id'],
        'tutor_id': row['tutor_id'],
        'start_time': row['start_time'],
        'end_time': row['end_time'],
        'status': row['status'],
        'course': row['course']
      };

      if (row['status'] == 'booked' && row['student_id'] != null) {
        session['student'] = {
          'id': row['student_id'],
        };
      }

      return session;
    }).toList();

  }













// Tutor-specific session retrieval
static Future<List<Map<String, dynamic>>> getTutorSessions(int tutorId) async {
  final db = await database;

  final result = await db.query(
    'schedules',
    where: 'tutor_id = ?',
    whereArgs: [tutorId],
    orderBy: 'start_time ASC',
  );

  return result.map((row) {
    final session = {
      'session_id': row['id'],
      'tutor_id': row['tutor_id'],
      'student_id': row['student_id'],
      'start_time': row['start_time'],
      'end_time': row['end_time'],
      'status': row['status'],
      'course': row['course']
    };

    if (row['status'] == 'booked' && row['student_id'] != null) {
      session['student'] = {
        'id': row['student_id'],
      };
    }

    return session;
  }).toList();
}
















static Future<void> saveTutorSessions(int tutorId, List<Map<String, dynamic>> sessions) async {
  final db = await database;

  // Clear all sessions for this tutor
  await db.delete('schedules', where: 'tutor_id = ?', whereArgs: [tutorId]);

  final batch = db.batch();

  for (var session in sessions) {
    final int id = session['session_id'];
    final String startTime = session['start_time'];
    final String endTime = session['end_time'];
    final String status = session['status'];
    final String course = session['course'];

    int? student;
    if (status == 'booked' && session['student'] != null) {
      final s = session['student'];
      if (s is Map && s['id'] != null) {
        student = int.tryParse(s['id'].toString());
      }
    }

    batch.insert(
      'schedules',
      {
        'id': id,
        'tutor_id': tutorId,
        'student_id': student,
        'start_time': startTime,
        'end_time': endTime,
        'status': status,
        'course': course,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  await batch.commit(noResult: true);
}
















  static Future<void> deleteSessionById(int sessionId) async {
    final db = await database;
    await db.delete(
      'schedules',
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }







  static Future<Map<String, dynamic>?> getUserById(int pantherId) async {
    final db = await database;

    final result = await db.query(
      'user',
      where: 'panther_id = ?',
      whereArgs: [pantherId],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first;
    }

    return null;
  }







  static Future<void> savePendingAttendance({
    required int sessionId,
    required int studentId,
    required String timeScanned,
  }) async {
    final db = await database;

    await db.insert(
      'attendance_pending',
      {
        'schedule_id': sessionId,
        'student_id': studentId,
        'time_scanned': timeScanned,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }


static Future<void> syncPendingAttendance() async {
  final db = await database;

  final pending = await db.query('attendance_pending');

  for (final row in pending) {
    try {
      final int sessionId = row['schedule_id'] as int;
      final int studentId = row['student_id'] as int;
      final String timeScanned = row['time_scanned'] as String;

      final response = await ApiService.checkInStudent(
        sessionId: sessionId,
        studentId: studentId,
        timeScanned: timeScanned,
      );

      if (response['status'] == 'success') {
        await db.delete(
          'attendance_pending',
          where: 'id = ?',
          whereArgs: [row['id']],
        );
      }
    } catch (e) {
      print("⚠️ Failed to sync check-in ID ${row['id']}: $e");
    }
  }
}





static Future<Map<String, dynamic>?> getSessionForCurrentTimeslot() async {
  final db = await database;

  final now = DateTime.now().toIso8601String();

  final result = await db.query(
    'schedules',
    where: "start_time <= ? AND end_time >= ?",
    whereArgs: [now, now],
    limit: 1,
  );

  if (result.isNotEmpty) {
    return result.first;
  } else {
    return null;
  }
}



}


