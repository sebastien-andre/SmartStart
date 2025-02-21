from flask import Flask, request, jsonify
import mysql.connector
import random
import smtplib
from email.mime.text import MIMEText
import datetime

app = Flask(__name__)

# MySQL configuration - update with your credentials and database name
db_config = {
    'user': 'your_username',
    'password': 'your_password',
    'host': 'localhost',
    'database': 'your_database'
}

def get_db_connection():
    return mysql.connector.connect(**db_config)

def send_email(recipient, subject, message):
    # Update with your SMTP server details
    sender = "your_email@example.com"
    sender_password = "your_email_password"
    smtp_server = "smtp.example.com"
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

    # Check email ending based on the type
    if user_type == "tutor":
        if not email.endswith("@gsu.edu"):
            return jsonify({"status": "failure", "message": "incorrect email"}), 400
    elif user_type == "student":
        if not email.endswith("@student.gsu.edu"):
            return jsonify({"status": "failure", "message": "incorrect email"}), 400
    else:
        return jsonify({"status": "failure", "message": "Invalid user type"}), 400

    # Connect to the database
    conn = get_db_connection()
    cursor = conn.cursor()

    # Generate a unique 6-digit code (as a string)
    code = None
    while True:
        candidate = str(random.randint(100000, 999999))
        cursor.execute("SELECT code FROM codes WHERE code = %s", (candidate,))
        if not cursor.fetchone():
            code = candidate
            break

    now = datetime.datetime.now()

    try:
        # Insert the code into the codes table.
        # It is assumed that the 'code' column is set as PRIMARY KEY.
        cursor.execute(
            "INSERT INTO codes (code, email, type, created_at) VALUES (%s, %s, %s, %s)",
            (code, email, user_type, now)
        )
        conn.commit()
    except Exception as e:
        conn.rollback()
        return jsonify({"status": "failure", "message": "Database error"}), 500
    finally:
        cursor.close()
        conn.close()

    # Prepare email content
    subject = "Welcome to Smart Start"
    message = (f"Welcome to Smart Start!\n"
               f"Your verification code is {code}.\n"
               "This code expires in 20 minutes.")
    if not send_email(email, subject, message):
        return jsonify({"status": "failure", "message": "Error sending email"}), 500

    return jsonify({"status": "success", "message": "Verification code sent"}), 200

@app.route('/verify_code', methods=['POST'])
def verify_code():
    data = request.get_json()
    code = data.get('code')

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("SELECT * FROM codes WHERE code = %s", (code,))
    record = cursor.fetchone()

    if not record:
        cursor.close()
        conn.close()
        return jsonify({"status": "failure", "message": "Invalid code"}), 400

    created_at = record['created_at']
    now = datetime.datetime.now()

    # Check if the code is older than 20 minutes
    if now - created_at > datetime.timedelta(minutes=20):
        cursor.execute("DELETE FROM codes WHERE code = %s", (code,))
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({"status": "failure", "message": "Expired code"}), 400

    # Code is valid; add the user to the 'users' table.
    email = record['email']
    user_type = record['type']
    try:
        cursor.execute(
            "INSERT INTO users (email, type, created_at) VALUES (%s, %s, %s)",
            (email, user_type, now)
        )
        # Remove the code after successful verification.
        cursor.execute("DELETE FROM codes WHERE code = %s", (code,))
        conn.commit()
    except Exception as e:
        conn.rollback()
        return jsonify({"status": "failure", "message": "Database error"}), 500
    finally:
        cursor.close()
        conn.close()

    return jsonify({"status": "success", "message": "User verified and created"}), 200

if __name__ == '__main__':
    # Bind to 0.0.0.0 so that the service is accessible on your network.
    app.run(host='0.0.0.0', port=5000, debug=True)

