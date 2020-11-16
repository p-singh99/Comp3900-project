from flask import request
from flask_restful import Resource
from functools import wraps
import datetime
import jwt
import bcrypt
from flask_restful import Api, Resource, reqparse
import user_functions as uf
import dbfunctions as df


class Settings(Resource):
	@uf.token_required
	def get(self):
		conn, cur = df.get_conn()
		user_id = uf.get_user_id()
		cur.execute("SELECT email FROM users WHERE id=%s", (user_id,))
		email = cur.fetchone()[0]
		df.close_conn(conn, cur)
		return {"email" : email}
        
	@uf.token_required
	def put(self):
		user_id = uf.get_user_id()
		conn, cur = df.get_conn()
		#get arguments from json request body
		parser = reqparse.RequestParser(bundle_errors=True)
		parser.add_argument('oldpassword', type=str, required=True, help="Need old password", location="json")
		parser.add_argument('newpassword', type=str, location="json")
		parser.add_argument('newemail', type=str, location="json")
		args = parser.parse_args()
		hashedpassword = ""
		# check current password
		cur.execute("SELECT hashedpassword FROM users WHERE id=%s", (user_id,))
		old_pw = cur.fetchone()[0].strip()
		if bcrypt.checkpw(args["oldpassword"].encode('UTF-8'), old_pw.encode('utf-8')):
			if args["newpassword"]:
				if args["oldpassword"] != args["newpassword"]:
					# change password
					password = args["newpassword"]
					password = password.encode('UTF-8')
					hashedpassword = bcrypt.hashpw(password, bcrypt.gensalt())
			if args['newemail']:
				# change email
				cur.execute("SELECT email FROM users where email=%s", (args['newemail'],))
				if cur.fetchone():
					cur.execute("SELECT email FROM users where email=%s and id=%s", (args['newemail'], user_id))
					if not cur.fetchone():
						df.close_conn(conn, cur)
						return {"error": "Email already exists"}, 400

				cur.execute("UPDATE users SET email=%s WHERE id=%s", (args['newemail'], user_id))
			if hashedpassword:
				cur.execute("UPDATE users SET hashedpassword=%s WHERE id=%s", (hashedpassword.decode('UTF-8'), user_id))
			conn.commit()
			df.close_conn(conn, cur)
			return {"data" : "success"}, 200
		df.close_conn(conn,cur)
		return {"error" : "wrong password"}, 400