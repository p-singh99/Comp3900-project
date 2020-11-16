from flask import request
from flask_restful import Resource
from functools import wraps
from user_functions import *
import dbfunctions as df
import bcrypt

class Login(Resource):
	def post(self):
		username = request.form.get('username').lower()
		password = request.form.get('password')
		conn, cur = df.get_conn()
		# Check if username exists
		cur.execute("SELECT username, hashedpassword FROM users WHERE username=%s OR email=%s", (username, username))
		res = cur.fetchone()
		if res:
			# get id for token authentication
			cur.execute("select id from users where username=%s or email=%s", (username,username))
			user_id = cur.fetchone()[0]
			df.close_conn(conn, cur)
			username = res[0].strip()
			pw = res[1].strip()
			pw = pw.encode('UTF-8')
			password = request.form.get('password')
			if bcrypt.checkpw(password.encode('UTF-8'), pw):
				return {'token' : create_token(user_id), 'user': username}, 200
		else:
			df.close_conn(conn, cur)
		return {"error" : "Login Failed"}, 401