from flask import request
from flask_restful import Resource
from functools import wraps
import user_functions as uf
import dbfunctions as df
import bcrypt

class Users(Resource):
	def post(self):
		conn, cur = df.get_conn()
		username = request.form.get('username').lower()
		email = request.form.get('email').lower()
		passw = request.form.get('password')
		pw = passw.encode('UTF-8')
		hashed = bcrypt.hashpw(pw, bcrypt.gensalt())
		error = False
		error_msg = []
		# check if username exists in database
		cur.execute("SELECT * FROM users WHERE username=%s",(username,))
		if cur.fetchone():
			error = True
			error_msg.append("Username already exists")
		# check if email exists in database
		cur.execute("SELECT * FROM users WHERE email=%s", (email,))
		if cur.fetchone():
			error = True
			error_msg.append("Email already exists")
		if error:
			cur.close()
			return {"error": error_msg}, 409
		cur.execute("insert into users (username, email, hashedpassword) values (%s, %s, %s)", (username, email, hashed.decode("UTF-8")))
		conn.commit()
		# get id for token authentication
		cur.execute("select id from users where username=%s", (username,))
		user_id = cur.fetchone()[0]
		df.close_conn(conn, cur)
		# return token
		return {'token' : uf.create_token(user_id), 'user': username}, 201