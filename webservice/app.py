from flask import Flask, request, jsonify, send_file
import sqlite3
import random
import datetime
import os
import smtplib
from email.mime.text import MIMEText
import io

app = Flask(__name__)

DB_NAME = "smart_start.db"


def get_db_connection():
    conn = sqlite3.connect(DB_NAME)
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    """Drops and recreates the database with updated schema."""
    if os.path.exists(DB_NAME):
        os.remove(DB_NAME)

    conn = sqlite3.connect(DB_NAME)
    cursor = conn.cursor()

    cursor.executescript("""
        CREATE TABLE users (
            panther_id INTEGER PRIMARY KEY,
            firstName TEXT NOT NULL,
            lastName TEXT NOT NULL,
            email TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL,
            roles TEXT NOT NULL,
            courses TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE codes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            code TEXT NOT NULL,
            email TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE schedules (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tutor_id INTEGER NOT NULL,
            student_id INTEGER DEFAULT NULL,
            start_time TEXT NOT NULL,
            end_time TEXT NOT NULL,
            status TEXT CHECK(status IN ('available', 'booked')) DEFAULT 'available',
            course TEXT,
            FOREIGN KEY(tutor_id) REFERENCES users(panther_id),
            FOREIGN KEY(student_id) REFERENCES users(panther_id)
        );

       CREATE TABLE attendance (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            schedule_id INTEGER NOT NULL,
            scheduled_student INTEGER NOT NULL,
            showed_student INTEGER DEFAULT NULL,
            time_scanned TIMESTAMP DEFAULT NULL,
            checkin_time TIMESTAMP DEFAULT NULL,
            status TEXT CHECK(status IN ('present', 'late', 'absent')) DEFAULT NULL,
            FOREIGN KEY(schedule_id) REFERENCES schedules(id),
            FOREIGN KEY(scheduled_student) REFERENCES users(panther_id),
            FOREIGN KEY(showed_student) REFERENCES users(panther_id)
        );

    """)


    conn.commit()
    conn.close()


@app.route('/reset-db', methods=['POST'])
def reset_db():
    init_db()
    return jsonify({"message": "Database has been reset."})


@app.route('/drop-schedules-attendance', methods=['POST'])
def drop_schedules_attendance():
    conn = sqlite3.connect(DB_NAME)
    cursor = conn.cursor()

    # Clear rows
    cursor.execute("DELETE FROM schedules;")
    cursor.execute("DELETE FROM attendance;")

    # Reset AUTOINCREMENT counters
    cursor.execute("DELETE FROM sqlite_sequence WHERE name='schedules';")
    cursor.execute("DELETE FROM sqlite_sequence WHERE name='attendance';")

    conn.commit()
    conn.close()
    return jsonify({"message": "Schedules and Attendance tables cleared."})



@app.route('/all-data', methods=['GET'])
def all_data():
    conn = sqlite3.connect(DB_NAME)
    cursor = conn.cursor()
    tables = ['users', 'codes', 'schedules', 'attendance']
    result = {}

    for table in tables:
        try:
            cursor.execute(f"SELECT * FROM {table}")
            cols = [column[0] for column in cursor.description]
            rows = cursor.fetchall()
            result[table] = [dict(zip(cols, row)) for row in rows]
        except sqlite3.OperationalError:
            result[table] = "Table not found."

    conn.close()
    return jsonify(result)















# Verfication


def send_email(recipient, subject, message):
    """Send a verification email."""
    sender = "smartstartgsu@gmail.com"
    sender_password = "qvny cijh vitz npsu"
    smtp_server = "smtp.gmail.com"
    smtp_port = 587

    msg = MIMEText(message)
    msg['Subject'] = subject
    msg['From'] = sender
    msg['To'] = recipient

    try:
        server = smtplib.SMTP(smtp_server, smtp_port)
        server.starttls()
        server.login(sender, sender_password)
        server.send_message(msg)
        server.quit()
        return True
    except Exception as e:
        print("Error sending email:", e)
        return False
    


@app.route('/send_verification', methods=['POST'])
def send_verification():
    data = request.get_json()
    email = data.get('email')
    user_type = data.get('type', '').lower()

    print(f"📧 Verification requested for: {email}, type: {user_type}")

    # Basic check for valid GSU email
    if not (email.endswith("@gsu.edu") or email.endswith("@student.gsu.edu")):
        return jsonify({"status": "failure", "message": "Invalid GSU email"}), 400

    if user_type not in ["tutor", "student", "both"]:
        return jsonify({"status": "failure", "message": "Invalid user type"}), 400

    conn = get_db_connection()
    cursor = conn.cursor()

    mode = data.get('mode', '').lower()  # <- new line to get mode

    # Allow code only for new registrations, unless in reset mode
    cursor.execute("SELECT panther_id FROM users WHERE email = ?", (email,))
    existing_user = cursor.fetchone()

    if existing_user and mode != "reset":
        cursor.close()
        conn.close()
        return jsonify({"status": "failure", "message": "User already exists"}), 400


    # Generate unique 6-digit code
    code = None
    while True:
        candidate = str(random.randint(100000, 999999))
        cursor.execute("SELECT id FROM codes WHERE code = ?", (candidate,))
        if not cursor.fetchone():
            code = candidate
            break

    now = datetime.datetime.now()

    try:
        cursor.execute(
            "INSERT INTO codes (code, email, created_at) VALUES (?, ?, ?)",
            (code, email, now)
        )
        conn.commit()
    except Exception as e:
        print("❌ Database error inserting code:", e)
        conn.rollback()
        cursor.close()
        conn.close()
        return jsonify({"status": "failure", "message": "Database error"}), 500

    cursor.close()
    conn.close()

    # Send the email
    subject = "SmartStart Email Verification"
    message = f"""
Welcome to SmartStart!
Your verification code is: {code}
This code expires in 20 minutes.
"""

    if not send_email(email, subject, message):
        return jsonify({"status": "failure", "message": "Failed to send email"}), 500

    return jsonify({"status": "success", "message": "Verification code sent"}), 200



@app.route('/verify_code', methods=['POST'])
def verify_code():
    data = request.get_json()
    email = data.get('email')
    code = data.get('code')

    if not email or not code:
        return jsonify({"status": "failure", "message": "Missing email or code"}), 400

    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute(
        "SELECT created_at FROM codes WHERE email = ? AND code = ?", (email, code)
    )
    row = cursor.fetchone()

    if not row:
        cursor.close()
        conn.close()
        return jsonify({"status": "failure", "message": "Invalid code or email"}), 400

    created_time = datetime.datetime.fromisoformat(row['created_at'])
    now = datetime.datetime.now()
    elapsed = (now - created_time).total_seconds()

    if elapsed > 1200:  # 20 minutes
        cursor.execute("DELETE FROM codes WHERE email = ? AND code = ?", (email, code))
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({"status": "failure", "message": "Code expired"}), 400

    cursor.close()
    conn.close()
    return jsonify({"status": "success", "message": "Code verified"}), 200


@app.route('/delete_code', methods=['POST'])
def delete_code():
    data = request.get_json()
    email = data.get('email')

    if not email:
        return jsonify({"status": "failure", "message": "Missing email"}), 400

    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM codes WHERE email = ?", (email,))
    conn.commit()
    cursor.close()
    conn.close()

    return jsonify({"status": "success", "message": "Verification code deleted"}), 200







@app.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    print("\n\n\n📨 Registering:", data, "\n\n\n")
    panther_id = data.get('panther_id')
    firstName = data.get('firstName')
    lastName = data.get('lastName')
    email = data.get('email')
    password = data.get('password')
    roles = data.get('roles')
    courses = data.get('courses', '')
    print(f"📨 Registering {email} with roles: {roles}")
    print("🧾 Inserting into users:", panther_id, firstName, lastName, email, password, roles, courses)
    

    if not panther_id or not firstName or not lastName or not email or not password or not roles:
        return jsonify({"status": "failure", "message": "Missing required fields"}), 400

    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute("SELECT panther_id FROM users WHERE email = ?", (email,))
    if cursor.fetchone():
        conn.close()
        return jsonify({"status": "failure", "message": "Email already registered"}), 409

    try:
        
        cursor.execute("""
            INSERT INTO users (panther_id, firstName, lastName, email, password, roles, courses)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, (panther_id, firstName, lastName, email, password, roles, courses))
        conn.commit()

        # Optional: delete code after successful registration
        cursor.execute("DELETE FROM codes WHERE email = ?", (email,))
        conn.commit()

        conn.close()
        return jsonify({"status": "success", "message": "User registered successfully"}), 200
    except Exception as e:
        conn.rollback()
        conn.close()
        print("❌ Registration error:", e)
        return jsonify({"status": "failure", "message": "Database error"}), 500

















# Login





@app.route('/device_login', methods=['POST'])
def device_login():
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')

    if not email or not password:
        return jsonify({"status": "failure", "message": "Missing email or password"}), 400

    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT panther_id, firstName, lastName, email, password, roles, courses
        FROM users
        WHERE email = ?
    """, (email,))
    user = cursor.fetchone()
    print("📤 Sending user back:", dict(user) if user else "None")

    conn.close()
    

    if not user or user["password"] != password:
        return jsonify({"status": "failure", "message": "Invalid credentials"}), 401

    return jsonify({
        "status": "success",
        "message": "Login successful",
        "user": {
            "panther_id": user["panther_id"],
            "firstName": user["firstName"],
            "lastName": user["lastName"],
            "email": user["email"],
            "roles": user["roles"],
            "courses": user["courses"] or ""
        }
    }), 200














# Student scheduling:

@app.route('/student_sessions_json', methods=['GET'])
def student_sessions_json():
    student_id = request.args.get('student_id')

    if student_id is None:
        return jsonify({"status": "failure", "message": "Missing student_id"}), 400

    conn = get_db_connection()
    cursor = conn.cursor()

    query = """
        SELECT s.id, s.start_time, s.end_time, s.status,
               s.tutor_id, s.student_id, s.course,
               u.email AS tutor_email,
               su.email AS student_email
        FROM schedules s
        LEFT JOIN users u ON s.tutor_id = u.panther_id
        LEFT JOIN users su ON s.student_id = su.panther_id
        WHERE (
            s.status = 'available' AND s.tutor_id != ?
        ) OR (
            s.status = 'booked' AND s.student_id = ?
        )
        ORDER BY s.start_time
    """

    cursor.execute(query, (student_id, student_id))
    sessions = cursor.fetchall()
    conn.close()

    result = []
    for s in sessions:
        session = {
            "session_id": s["id"],
            "start_time": s["start_time"],
            "end_time": s["end_time"],
            "status": s["status"],
            "tutor_id": s["tutor_id"],
            "course": s["course"],
            "tutor_email": s["tutor_email"],
        }

        if s["status"] == "booked":
            session["student"] = {
                "id": s["student_id"],
                "email": s["student_email"]
            }

        result.append(session)

    return jsonify({"status": "success", "sessions": result}), 200












# Tutor Schedulng




@app.route('/tutor_sessions_json', methods=['GET'])
def tutor_sessions_json():
    tutor_id = request.args.get('tutor_id')

    if tutor_id is None:
        return jsonify({"status": "failure", "message": "Missing tutor_id"}), 400

    conn = get_db_connection()
    cursor = conn.cursor()

    query = """
        SELECT s.id, s.start_time, s.end_time, s.status,
               s.tutor_id, s.student_id, s.course,
               u.email AS student_email
        FROM schedules s
        LEFT JOIN users u ON s.student_id = u.panther_id
        WHERE s.tutor_id = ?
        ORDER BY s.start_time
    """

    cursor.execute(query, (tutor_id,))
    sessions = cursor.fetchall()
    conn.close()

    result = []
    for s in sessions:
        session = {
            "session_id": s["id"],
            "start_time": s["start_time"],
            "end_time": s["end_time"],
            "status": s["status"],
            "course": s['course'],
            "tutor_id": s["tutor_id"],
        }

        if s["status"] == "booked" and s["student_id"] is not None:
            session["student"] = {
                "id": s["student_id"],
                "email": s["student_email"]
            }

        result.append(session)

    return jsonify({"status": "success", "sessions": result}), 200












@app.route('/upload_schedule_json', methods=['POST'])
def upload_schedule_json():
    data = request.get_json()
    tutor_id = data.get('tutor_id')
    sessions = data.get('sessions')
    repeat = data.get('repeat', 'none').lower()  # 'none', 'weekly', 'biweekly'
    times = int(data.get('times', 1))
    course = data.get('course', '')

    if not tutor_id or not sessions:
        return jsonify({"status": "failure", "message": "Missing tutor_id or sessions"}), 400

    if repeat not in ['none', 'weekly', 'biweekly']:
        return jsonify({"status": "failure", "message": "Invalid repeat value"}), 400

    conn = get_db_connection()
    cursor = conn.cursor()

    interval_days = 0
    if repeat == 'weekly':
        interval_days = 7
    elif repeat == 'biweekly':
        interval_days = 14

    added = 0
    skipped = 0
    for session in sessions:
        start = session.get('start_time')
        end = session.get('end_time')

        if not start or not end:
            continue  # skip incomplete entries

        try:
            start_dt = datetime.datetime.fromisoformat(start)
            end_dt = datetime.datetime.fromisoformat(end)

            for i in range(times):
                repeated_start = start_dt + datetime.timedelta(days=i * interval_days)
                repeated_end = end_dt + datetime.timedelta(days=i * interval_days)

                cursor.execute("""
                    SELECT id FROM schedules
                    WHERE tutor_id = ? AND start_time = ? AND end_time = ?
                """, (tutor_id, repeated_start.isoformat(), repeated_end.isoformat()))
                conflict = cursor.fetchone()

                if conflict:
                    print(f"⚠️ Skipped duplicate session: {repeated_start} - {repeated_end}")
                    skipped += 1
                    continue

                cursor.execute("""
                    INSERT INTO schedules (tutor_id, start_time, end_time, status, course)
                    VALUES (?, ?, ?, 'available', ?)
                """, (tutor_id, repeated_start.isoformat(), repeated_end.isoformat(), course))
                added += 1

        except Exception as e:
            print(f"❌ Error adding session {start}–{end}:", e)

    conn.commit()
    conn.close()

    # 🧠 Generate final message based on whether anything was skipped
    if skipped > 0:
        message = f"{added} session(s) added, {skipped} session(s) skipped."
    else:
        message = f"{added} session(s) added successfully."

    return jsonify({
        "status": "success",
        "added": added,
        "skipped": skipped,
        "message": message
    }), 200
















@app.route('/unschedule_session', methods=['POST'])
def unschedule_session():
    data = request.get_json()
    session_id = data.get('session_id')

    if not session_id:
        return jsonify({"status": "failure", "message": "Missing session_id"}), 400

    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute("SELECT start_time, status FROM schedules WHERE id = ?", (session_id,))
    session = cursor.fetchone()

    if not session:
        conn.close()
        return jsonify({"status": "failure", "message": "Session not found"}), 404

    start_time = datetime.datetime.fromisoformat(session['start_time'])

    time_until_session = start_time - datetime.datetime.now()
    if time_until_session.total_seconds() < 48 * 3600:
        conn.close()
        return jsonify({"status": "failure", "message": "Cannot unschedule within 48 hours"}), 403

    try:
        # Remove from attendance table first
        cursor.execute("DELETE FROM attendance WHERE schedule_id = ?", (session_id,))
        # Then remove from schedules
        cursor.execute("DELETE FROM schedules WHERE id = ?", (session_id,))
        conn.commit()
        conn.close()

        return jsonify({"status": "success", "message": "Session unscheduled successfully"}), 200
    except Exception as e:
        conn.rollback()
        conn.close()
        print("❌ Unschedule error:", e)
        return jsonify({"status": "failure", "message": "Error unscheduling session"}), 500






@app.route('/delete_schedule_json', methods=['POST'])
def delete_schedule_json():
    data = request.get_json()
    tutor_id = data.get('tutor_id')
    sessions = data.get('sessions')

    if not tutor_id or not sessions:
        return jsonify({"status": "failure", "message": "Missing tutor_id or sessions"}), 400

    conn = get_db_connection()
    cursor = conn.cursor()

    deleted = 0
    for session in sessions:
        start = session.get('start_time')
        end = session.get('end_time')

        if not start or not end:
            continue

        # Find matching schedule ID(s)
        cursor.execute("""
            SELECT id FROM schedules
            WHERE tutor_id = ? AND start_time = ? AND end_time = ?
        """, (tutor_id, start, end))

        rows = cursor.fetchall()
        for row in rows:
            schedule_id = row["id"]
            # Delete from attendance first
            cursor.execute("DELETE FROM attendance WHERE schedule_id = ?", (schedule_id,))
            # Then delete from schedules
            cursor.execute("DELETE FROM schedules WHERE id = ?", (schedule_id,))
            deleted += 1

    conn.commit()
    conn.close()

    return jsonify({"status": "success", "deleted": deleted}), 200







@app.route('/sync_schedule_json', methods=['GET'])
def sync_schedule_json():
    tutor_id = request.args.get('tutor_id')
    start = request.args.get('start')
    end = request.args.get('end')

    if tutor_id is None:
        return jsonify({"status": "failure", "message": "Missing tutor_id"}), 400

    conn = get_db_connection()
    cursor = conn.cursor()

    query = """
        SELECT s.id, s.start_time, s.end_time, s.status, s.course,
               u.panther_id AS student_id, u.email AS student_email
        FROM schedules s
        LEFT JOIN users u ON s.student_id = u.panther_id
    """
    params = []

    if tutor_id != "0":
        query += " WHERE s.tutor_id = ?"
        params.append(tutor_id)

    if start:
        if "WHERE" in query:
            query += " AND s.start_time >= ?"
        else:
            query += " WHERE s.start_time >= ?"
        params.append(start)

    if end:
        if "WHERE" in query:
            query += " AND s.end_time <= ?"
        else:
            query += " WHERE s.end_time <= ?"
        params.append(end)

    query += " ORDER BY s.start_time"

    cursor.execute(query, params)
    sessions = cursor.fetchall()
    conn.close()

    result = []
    for s in sessions:
        session = {
            "session_id": s["id"],
            "start_time": s["start_time"],
            "end_time": s["end_time"],
            "status": s["status"]
        }
        if s["status"] == "booked" and s["student_id"]:
            session["student"] = {
                "id": s["student_id"],
                "email": s["student_email"]
            }
        result.append(session)

    return jsonify({"status": "success", "sessions": result}), 200









# Reset Password



@app.route('/reset_password', methods=['POST'])
def reset_password():
    data = request.get_json()
    email = data.get('email')
    code = data.get('code')
    new_password = data.get('new_password')

    if not email or not code or not new_password:
        return jsonify({"status": "failure", "message": "Missing email, code, or new_password"}), 400

    conn = get_db_connection()
    cursor = conn.cursor()

    # Verify the code
    cursor.execute(
        "SELECT created_at FROM codes WHERE email = ? AND code = ?", (email, code)
    )
    row = cursor.fetchone()

    if not row:
        conn.close()
        return jsonify({"status": "failure", "message": "Invalid code or email"}), 400

    created_time = datetime.datetime.fromisoformat(row['created_at'])
    now = datetime.datetime.now()
    elapsed = (now - created_time).total_seconds()

    if elapsed > 1200:  # 20 minutes
        cursor.execute("DELETE FROM codes WHERE email = ? AND code = ?", (email, code))
        conn.commit()
        conn.close()
        return jsonify({"status": "failure", "message": "Code expired"}), 400

    # Reset the password
    try:
        cursor.execute(
            "UPDATE users SET password = ? WHERE email = ?",
            (new_password, email)
        )
        cursor.execute("DELETE FROM codes WHERE email = ?", (email,))
        conn.commit()
        conn.close()
        return jsonify({"status": "success", "message": "Password reset successful"}), 200

    except Exception as e:
        print("❌ Password reset error:", e)
        conn.rollback()
        conn.close()
        return jsonify({"status": "failure", "message": "Error resetting password"}), 500













# Student Booking


@app.route('/student_booked_sessions', methods=['GET'])
def student_booked_sessions():
    student_id = request.args.get('student_id')
    if not student_id:
        return jsonify({"status": "failure", "message": "Missing student_id"}), 400

    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT id, start_time, end_time, tutor_id
        FROM schedules
        WHERE student_id = ?
        ORDER BY start_time
    """, (student_id,))

    sessions = cursor.fetchall()
    conn.close()

    result = []
    for s in sessions:
        result.append({
            "session_id": s["id"],
            "start_time": s["start_time"],
            "end_time": s["end_time"],
            "tutor_id": s["tutor_id"],
            "course": s["course"]
        })

    return jsonify({"status": "success", "sessions": result}), 200






@app.route('/book_session', methods=['POST'])
def book_session():
    data = request.get_json()
    student_id = data.get('student_id')
    session_id = data.get('session_id')
    course = data.get('course')

    if not student_id or not session_id:
        return jsonify({"status": "failure", "message": "Missing student_id or session_id"}), 400

    conn = get_db_connection()
    cursor = conn.cursor()

    # Check if the session is available
    cursor.execute("""
        SELECT status FROM schedules WHERE id = ?
    """, (session_id,))
    row = cursor.fetchone()

    if not row:
        conn.close()
        return jsonify({"status": "failure", "message": "Session not found"}), 404

    if row["status"] != "available":
        conn.close()
        return jsonify({"status": "failure", "message": "Session is already booked"}), 409

    try:
        # Update schedule with student info
        cursor.execute("""
            UPDATE schedules
            SET student_id = ?, status = 'booked'
            WHERE id = ?
        """, (student_id, session_id))


        cursor.execute("""
            INSERT INTO attendance (schedule_id, scheduled_student)
            VALUES (?, ?)
        """, (session_id, student_id))


        conn.commit()
        conn.close()
        return jsonify({"status": "success", "message": "Session booked successfully"}), 200

    except Exception as e:
        conn.rollback()
        conn.close()
        print("Booking error:", e)
        return jsonify({"status": "failure", "message": "Error booking session"}), 500







# Delete Session:

@app.route('/unbook_session', methods=['POST'])
def unbook_session():
    data = request.get_json()
    student_id = data.get('student_id')
    session_id = data.get('session_id')

    if not student_id or not session_id:
        return jsonify({"status": "failure", "message": "Missing student_id or session_id"}), 400

    conn = get_db_connection()
    cursor = conn.cursor()

    # Check if session is booked by this student
    cursor.execute("""
        SELECT student_id, status FROM schedules WHERE id = ?
    """, (session_id,))
    row = cursor.fetchone()

    if not row:
        conn.close()
        return jsonify({"status": "failure", "message": "Session not found"}), 404

    if row["student_id"] != int(student_id) or row["status"] != "booked":
        conn.close()
        return jsonify({"status": "failure", "message": "Session not booked by this student"}), 403

    try:
        # Update schedule to remove student and mark available
        cursor.execute("""
            UPDATE schedules
            SET student_id = NULL, status = 'available'
            WHERE id = ?
        """, (session_id,))

        # Optionally remove attendance record
        cursor.execute("""
            DELETE FROM attendance
            WHERE schedule_id = ? AND scheduled_student = ?
        """, (session_id, student_id))

        conn.commit()
        conn.close()
        return jsonify({"status": "success", "message": "Session unbooked successfully"}), 200

    except Exception as e:
        conn.rollback()
        conn.close()
        print("Unbooking error:", e)
        return jsonify({"status": "failure", "message": "Error unbooking session"}), 500














# Attendance


# @app.route('/checkin', methods=['POST'])
# def checkin():
#     data = request.get_json()
#     student_id = data.get('student_id')
#     tutor_id = data.get('tutor_id')
#     time_scanned_str = data.get('time_scanned')

#     if not student_id or not tutor_id or not time_scanned_str:
#         return jsonify({"status": "failure", "message": "Missing required fields"}), 400

#     try:
#         # time_scanned = datetime.datetime.fromisoformat(time_scanned_str)
#         time_scanned_str = time_scanned_str.rstrip("Z")
#         time_scanned = datetime.datetime.fromisoformat(time_scanned_str)

#     except ValueError:
#         return jsonify({"status": "failure", "message": "Invalid time format"}), 400

#     checkin_time = datetime.datetime.utcnow()  # for server log only

#     conn = get_db_connection()
#     cursor = conn.cursor()

#     # Use time_scanned (from app) to find matching session
#     cursor.execute("""
#         SELECT id, start_time, student_id
#         FROM schedules
#         WHERE tutor_id = ?
#             AND julianday(start_time) BETWEEN julianday(?) - (15.0/1440) AND julianday(?) + (15.0/1440)
#         ORDER BY start_time ASC
#         LIMIT 1
#     """, (tutor_id, time_scanned_str, time_scanned_str))
#     session = cursor.fetchone()

#     if not session:
#         conn.close()
#         return jsonify({"status": "failure", "message": "No active session found"}), 404

#     session_id = session["id"]
#     start_time = datetime.datetime.fromisoformat(session["start_time"])
#     scheduled_student = session["student_id"]

#     # Check for duplicate check-in
#     cursor.execute("""
#         SELECT id FROM attendance
#         WHERE schedule_id = ? AND showed_student = ?
#     """, (session_id, student_id))
#     if cursor.fetchone():
#         conn.close()
#         return jsonify({
#             "status": "failure",
#             "message": "Student already checked in for this session"
#         }), 409

#     # Time delta in seconds based on app's scan time
#     delta = (time_scanned - start_time).total_seconds()

#     if student_id == scheduled_student:
#         status = "present" if delta <= 900 else "late"
#     else:
#         # Always allow replacement, regardless of time
#         status = "present"

#         # Mark the scheduled student as absent (if not already marked)
#         cursor.execute("""
#             SELECT id FROM attendance
#             WHERE schedule_id = ? AND showed_student IS NULL
#         """, (session_id,))
#         if not cursor.fetchone():
#             cursor.execute("""
#                 INSERT INTO attendance (schedule_id, scheduled_student, showed_student, checkin_time, time_scanned, status)
#                 VALUES (?, ?, NULL, ?, ?, 'absent')
#             """, (session_id, scheduled_student, checkin_time, time_scanned))


#         # Safe to replace
#         status = "present"

#         # Mark the scheduled student as absent (if not already marked)
#         cursor.execute("""
#             SELECT id FROM attendance
#             WHERE schedule_id = ? AND showed_student IS NULL
#         """, (session_id,))
#         if not cursor.fetchone():
#             cursor.execute("""
#                 INSERT INTO attendance (schedule_id, scheduled_student, showed_student, checkin_time, time_scanned, status)
#                 VALUES (?, ?, NULL, ?, ?, 'absent')
#             """, (session_id, scheduled_student, checkin_time, time_scanned))

#     # Record this student's check-in
#     cursor.execute("""
#         INSERT INTO attendance (schedule_id, scheduled_student, showed_student, checkin_time, time_scanned, status)
#         VALUES (?, ?, ?, ?, ?, ?)
#     """, (session_id, scheduled_student, student_id, checkin_time, time_scanned, status))

#     conn.commit()
#     conn.close()

#     return jsonify({"status": "success", "message": f"Check-in recorded as '{status}'"}), 200





@app.route('/checkin', methods=['POST'])
def checkin():
    data = request.get_json()
    student_id = data.get('student_id')
    session_id = data.get('session_id')
    time_scanned_str = data.get('time_scanned')

    if not student_id or not session_id or not time_scanned_str:
        return jsonify({"status": "failure", "message": "Missing required fields"}), 400

    try:
        time_scanned_str = time_scanned_str.rstrip("Z")
        time_scanned = datetime.datetime.fromisoformat(time_scanned_str)
    except ValueError:
        return jsonify({"status": "failure", "message": "Invalid time format"}), 400

    checkin_time = datetime.datetime.utcnow()

    conn = get_db_connection()
    cursor = conn.cursor()

    # 🔁 Get session info directly from session_id
    cursor.execute("SELECT * FROM schedules WHERE id = ?", (session_id,))
    session = cursor.fetchone()

    if not session:
        conn.close()
        return jsonify({"status": "failure", "message": "Session not found"}), 404

    start_time = datetime.datetime.fromisoformat(session["start_time"])
    scheduled_student = session["student_id"]

    # 🔍 Check for duplicate check-in
    cursor.execute("""
        SELECT id FROM attendance
        WHERE schedule_id = ? AND showed_student = ?
    """, (session_id, student_id))
    if cursor.fetchone():
        conn.close()
        return jsonify({
            "status": "failure",
            "message": "Student already checked in for this session"
        }), 409

    delta = (time_scanned - start_time).total_seconds()

    if student_id == scheduled_student:
        status = "present" if delta <= 900 else "late"
    else:
        status = "present"
        # Mark the scheduled student absent if not already
        cursor.execute("""
            SELECT id FROM attendance
            WHERE schedule_id = ? AND showed_student IS NULL
        """, (session_id,))
        if not cursor.fetchone():
            cursor.execute("""
                INSERT INTO attendance (schedule_id, scheduled_student, showed_student, checkin_time, time_scanned, status)
                VALUES (?, ?, NULL, ?, ?, 'absent')
            """, (session_id, scheduled_student, checkin_time, time_scanned))

    # Record this student's check-in
    cursor.execute("""
        INSERT INTO attendance (schedule_id, scheduled_student, showed_student, checkin_time, time_scanned, status)
        VALUES (?, ?, ?, ?, ?, ?)
    """, (session_id, scheduled_student, student_id, checkin_time, time_scanned, status))

    conn.commit()
    conn.close()

    return jsonify({"status": "success", "message": f"Check-in recorded as '{status}'"}), 200























# Admin attendance records

@app.route('/attendance/all', methods=['GET'])
def get_all_attendance():
    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT a.id, a.schedule_id, a.scheduled_student, a.showed_student,
               a.checkin_time, a.time_scanned, a.status,
               ss.email AS scheduled_email, sh.email AS showed_email,
               s.start_time, s.end_time, s.tutor_id
        FROM attendance a
        JOIN schedules s ON a.schedule_id = s.id
        LEFT JOIN users ss ON a.scheduled_student = ss.panther_id
        LEFT JOIN users sh ON a.showed_student = sh.panther_id
        ORDER BY s.start_time ASC
    """)

    rows = cursor.fetchall()
    conn.close()

    records = []
    for row in rows:
        records.append({
            "attendance_id": row["id"],
            "schedule_id": row["schedule_id"],
            "scheduled_student": {
                "id": row["scheduled_student"],
                "email": row["scheduled_email"]
            },
            "showed_student": {
                "id": row["showed_student"],
                "email": row["showed_email"]
            } if row["showed_student"] else None,
            "status": row["status"],
            "time_scanned": row["time_scanned"],
            "checkin_time": row["checkin_time"],
            "session": {
                "start_time": row["start_time"],
                "end_time": row["end_time"],
                "tutor_id": row["tutor_id"]
            }
        })

    return jsonify({"status": "success", "records": records}), 200




@app.route('/attendance/student/<int:student_id>', methods=['GET'])
def get_student_attendance(student_id):
    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT a.id, a.schedule_id, a.scheduled_student, a.showed_student,
               a.checkin_time, a.time_scanned, a.status,
               s.start_time, s.end_time, s.tutor_id
        FROM attendance a
        JOIN schedules s ON a.schedule_id = s.id
        WHERE a.scheduled_student = ? OR a.showed_student = ?
        ORDER BY s.start_time ASC
    """, (student_id, student_id))

    rows = cursor.fetchall()
    conn.close()

    records = []
    for row in rows:
        records.append({
            "attendance_id": row["id"],
            "schedule_id": row["schedule_id"],
            "scheduled_student_id": row["scheduled_student"],
            "showed_student_id": row["showed_student"],
            "status": row["status"],
            "time_scanned": row["time_scanned"],
            "checkin_time": row["checkin_time"],
            "session": {
                "start_time": row["start_time"],
                "end_time": row["end_time"],
                "tutor_id": row["tutor_id"]
            }
        })

    return jsonify({"status": "success", "records": records}), 200











































# if __name__ == '__main__':
#     init_db()
#     app.run(debug=True, port=8000)


# if __name__ == '__main__':
#     if not os.path.exists(DB_NAME):
#         print("📦 Database not found. Initializing new DB...")
#         init_db()
#     else:
#         print("✅ Existing database detected. Skipping reinitialization.")
#     app.run(debug=True, port=8000)


if __name__ == '__main__':
    if not os.path.exists(DB_NAME):
        print("📦 Database not found. Initializing new DB...")
        init_db()
    else:
        print("✅ Existing database detected. Skipping reinitialization.")
    app.run(host='0.0.0.0', debug=True, port=8000)









