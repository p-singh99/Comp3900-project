from flask import Flask, jsonify, request
from flask_restful import Resource
from functools import wraps
from flask_restful import Api, Resource, reqparse
from user_functions import token_required, get_user_id
import dbfunctions as df
import bcrypt

class Self(Resource):
	@token_required
	def delete(self):
		conn, cur = df.get_conn()
		user_id = get_user_id()
		parser = reqparse.RequestParser(bundle_errors=True)
		parser.add_argument('password', type=str, required=True, help="Need old password", location="json")
		args = parser.parse_args()
		cur.execute("SELECT hashedpassword FROM users WHERE id=%s", (user_id,))
		old_pw = cur.fetchone()[0].strip()
		if bcrypt.checkpw(args["password"].encode('UTF-8'), old_pw.encode('utf-8')):
			
			# delete all subscriptions
			cur.execute("DELETE FROM subscriptions WHERE userId=%s", (user_id,))
			# delete podcast account
			cur.execute("DELETE FROM podcastratings WHERE userId=%s", (user_id,))
			# delete episode ratings
			cur.execute("DELETE FROM episoderatings WHERE userId=%s", (user_id,))
			# delete listens
			cur.execute("DELETE FROM listens WHERE userId=%s", (user_id,))
			# delete seach queries
			cur.execute("DELETE FROM searchqueries WHERE userId=%s", (user_id,))
			cur.execute("DELETE FROM notifications WHERE userid=%s", (user_id,))
			# delete from users
			cur.execute("DELETE FROM users WHERE id=%s", (user_id,))
		
			conn.commit()
			df.close_conn(conn,cur)
			return {"data" : "account deleted"}, 200
		else:
			df.close_conn(conn,cur)
			return {"error" : "wrong password"}, 400