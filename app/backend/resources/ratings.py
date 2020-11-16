from flask import request
from flask_restful import Resource, reqparse
from functools import wraps
import datetime
import user_functions as uf
import dbfunctions as df

class Ratings(Resource):
	def get(self, id):
		conn, cur = df.get_conn()
		user_id = uf.get_user_id()
		cur.execute("SELECT rating FROM podcastratings WHERE podcastid=%s and userid=%s", (id, user_id))
		res = cur.fetchone()
		rating = res[0] if res else None
		df.close_conn(conn, cur)
		return {"rating": rating}, 200

	def put(self,id):
		conn, cur = df.get_conn()
		user_id = uf.get_user_id()
		# get ratings limited to 1 to 5
		parser = reqparse.RequestParser()
		parser.add_argument('rating', type=int, required=True, choices=(1,2,3,4,5), help="Rating not valid", location="json")
		args = parser.parse_args()
		#check if already rated
		cur.execute("SELECT rating FROM podcastratings where userid=%s and podcastid=%s", (user_id, id))
		if cur.fetchone():
			cur.execute("UPDATE podcastratings SET rating=%s WHERE userid=%s and podcastid=%s", (args["rating"], user_id, id))
		else:
			cur.execute("INSERT INTO podcastratings (userid, podcastid, rating) VALUES (%s, %s, %s)", (user_id, id, args["rating"]))
		conn.commit()
		return {"success": "added"}
	