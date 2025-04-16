import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://192.168.1.17:8000';

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/device_login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> sendVerification(String email, String type, {String? mode}) async {
  final url = Uri.parse('$baseUrl/send_verification');

  final Map<String, dynamic> body = {
    'email': email,
    'type': type,
  };

  if (mode != null) {
    body['mode'] = mode;
  }

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(body),
  );

  return jsonDecode(response.body);
}


  static Future<Map<String, dynamic>> verifyCode(String email, String code) async {
    final url = Uri.parse('$baseUrl/verify_code');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );
    return jsonDecode(response.body);
  }








  static Future<Map<String, dynamic>> registerUser(
    int pantherId, String firstName, String lastName, String email, String password, String roles, String? courses) async {
    print("API Service attempting to register user with, $pantherId, $firstName, $lastName, $email, $password, $roles, $courses");
    final url = Uri.parse('$baseUrl/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'panther_id': pantherId,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
        'roles': roles,
        if (courses != null && courses.isNotEmpty) 'courses': courses,
      }),
    );
    return jsonDecode(response.body);
  }








static Future<Map<String, dynamic>> scheduleSession({
  required String tutorId,
  required DateTime startTime,
  required DateTime endTime,
  required String course,
  String recurrence = "none",
  int repeatTimes = 1,
}) async {
  final url = Uri.parse('$baseUrl/upload_schedule_json');

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'tutor_id': tutorId,
      'repeat': recurrence,
      'times': repeatTimes,
      'sessions': [
        {
          'start_time': startTime.toIso8601String(),
          'end_time': endTime.toIso8601String(),
        }
      ],
      'course': course,
    }),
  );

  final Map<String, dynamic> data = jsonDecode(response.body);

  // ✅ Check for duplicate skip warning
  if (data.containsKey('skipped') && data['skipped'] > 0) {
    return {
      "status": "partial",
      "message": data['message'] ?? "Some sessions were skipped due to duplication",
    };
  }

  // ✅ Return success or failure
  return {
    "status": data['status'],
    "message": data['message'] ?? '',
  };
}










static Future<Map<String, dynamic>> unscheduleSession(int sessionId) async {
  final url = Uri.parse('$baseUrl/unschedule_session');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'session_id': sessionId}),
  );

  return jsonDecode(response.body);
}



static Future<Map<String, dynamic>> deleteSession({
  required String tutorId,
  required List<Map<String, dynamic>> sessions,
}) async {
  final url = Uri.parse('$baseUrl/delete_schedule_json');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'tutor_id': tutorId,
      'sessions': sessions,
    }),
  );

  return jsonDecode(response.body);
}







  static Future<List<Map<String, dynamic>>> getSessions(String tutorId) async {
    final url = Uri.parse('$baseUrl/sync_schedule_json?tutor_id=$tutorId');

    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      final List<dynamic> sessions = json['sessions'] ?? [];

      return List<Map<String, dynamic>>.from(sessions);
    } else {
      throw Exception('Failed to fetch sessions from the server');
    }
  }










  static Future<Map<String, dynamic>> getAllTutorSessions({String? tutorId}) async {
    final url = tutorId != null
        ? Uri.parse('$baseUrl/sync_schedule_json?tutor_id=$tutorId')
        : Uri.parse('$baseUrl/sync_schedule_json');

    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception("Failed to fetch sessions from the server");
    }
    return jsonDecode(response.body);
  }







  static Future<Map<String, dynamic>> bookSession({
    required int studentId,
    required int sessionId,
  }) async {
    final url = Uri.parse('$baseUrl/book_session');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'student_id': studentId,
        'session_id': sessionId,
      }),
    );
    return jsonDecode(response.body);
  }





static Future<List<Map<String, dynamic>>> getStudentSessions(String studentId) async {
    final url = Uri.parse('$baseUrl/student_sessions_json?student_id=$studentId');

    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        final List<dynamic> sessions = data['sessions'] ?? [];
        return List<Map<String, dynamic>>.from(sessions);
      } else {
        throw Exception('API returned failure: ${data['message']}');
      }
    } else {
      throw Exception('Failed to fetch student sessions: ${response.statusCode}');
    }
}






static Future<List<Map<String, dynamic>>> getTutorSessions(String tutorId) async {
  final url = Uri.parse('$baseUrl/tutor_sessions_json?tutor_id=$tutorId');

  final response = await http.get(
    url,
    headers: {'Content-Type': 'application/json'},
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> data = jsonDecode(response.body);
    if (data['status'] == 'success') {
      return List<Map<String, dynamic>>.from(data['sessions']);
    } else {
      throw Exception('API returned failure: ${data['message']}');
    }
  } else {
    throw Exception('Failed to fetch tutor sessions: ${response.statusCode}');
  }
}







  static Future<Map<String, dynamic>> unbookSession({
    required int studentId,
    required int sessionId,
  }) async {
    final url = Uri.parse('$baseUrl/unbook_session');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'student_id': studentId,
        'session_id': sessionId,
      }),
    );

    return jsonDecode(response.body);
  }







  // static Future<Map<String, dynamic>> checkInStudent({
  //   required int studentId,
  //   required int tutorId,
  //   required String timeScanned,
  // }) async {
  //   final url = Uri.parse('$baseUrl/checkin');
  //   final response = await http.post(
  //     url,
  //     headers: {'Content-Type': 'application/json'},
  //     body: jsonEncode({
  //       'student_id': studentId,
  //       'tutor_id': tutorId,
  //       'time_scanned': timeScanned,
  //     }),
  //   );
  //   return jsonDecode(response.body);
  // }

static Future<Map<String, dynamic>> checkInStudent({
  required int studentId,
  required int sessionId,
  required String timeScanned,
}) async {
  final url = Uri.parse('$baseUrl/checkin');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'student_id': studentId,
      'session_id': sessionId,
      'time_scanned': timeScanned,
    }),
  );
  return jsonDecode(response.body);
}





}




