import requests

from flask import Flask, request, jsonify
import mysql.connector
import random
import smtplib
from email.mime.text import MIMEText
import datetime

app = Flask(__name__)

db_config = {
    'user': 'root',
    'password': '3kAF9saj!!!',
    'host': 'localhost',
    'database': 'smart_start'
}


BASE_URL = "http://localhost:8000"  

def test_send_verification():
    payload = {
        "email": "slee352@student.gsu.edu",  #
        "type": "student"                 
    }
    response = requests.post(f"{BASE_URL}/send_verification", json=payload)
    print("send_verification response:")
    print("Status Code:", response.status_code)
    print("Response JSON:", response.json())

def test_verify_code(code):
    payload = {"code": code}
    response = requests.post(f"{BASE_URL}/verify_code", json=payload)
    print("verify_code response:")
    print("Status Code:", response.status_code)
    print("Response JSON:", response.json())

if __name__ == '__main__':
    # Test sending the verification email
    test_send_verification()

    # After the email is sent, check your inbox for the verification code.
    # Enter the code below to test the verification endpoint.
    code = input("Enter the verification code you received via email: ").strip()
    test_verify_code(code)


    conn = mysql.connector.connect(**db_config)
    cursor = conn.cursor(dictionary=True)

    # Print contents of the 'users' table
    cursor.execute("SELECT * FROM users")
    users = cursor.fetchall()
    print("Users Table:")
    for user in users:
        print(user)

    # Print contents of the 'codes' table
    cursor.execute("SELECT * FROM codes")
    codes = cursor.fetchall()
    print("\nCodes Table:")
    for code in codes:
        print(code)

    cursor.close()
    conn.close()