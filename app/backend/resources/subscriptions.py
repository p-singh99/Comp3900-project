from flask import Flask, jsonify, request
from flask_restful import Resource
from functools import wraps
from flask_restful import Api, Resource, reqparse
from user_functions import token_required, get_user_id
import dbfunctions as df
import threading

# grabs subscriptions and posts a subscription between user and podcast
class Subscriptions(Resource):
	@token_required
	def get(self):
		conn, cur = df.get_conn()
		uid = get_user_id()
		cur.execute("SELECT p.title, p.author, p.description, p.id, r.rating, p.thumbnail FROM podcasts p, ratingsview r, subscriptions s \
			WHERE s.podcastId = p.id and s.userID = %s and r.id = p.id;", (uid,))
		podcasts = cur.fetchall()	# grabs all podcasts taht user is subscribed to
		results = []
		for p in podcasts:
			cur.execute("select count(podcastId) FROM subscriptions where podcastId = %s GROUP BY podcastId;", (p[3],))
			subscribers = cur.fetchone()
			title = p[0]
			author = p[1]
			description = p[2]
			pID = p[3]
			rating = f"{p[4]:.1f}"
			thumbnail = p[5]
			results.append({"subscribers" : subscribers, "title" : title, "author" : author, "description" : description, "pid" : pID, "rating": rating, "thumbnail": thumbnail})
		df.close_conn(conn, cur)
		return results, 200

	@token_required
	def post(self):
		conn, cur = df.get_conn()
		userID = get_user_id()
		parser = reqparse.RequestParser(bundle_errors=True)		#grabbing podcastid from request body
		parser.add_argument('podcastid', type=str, location="json")
		args = parser.parse_args()
		podcastID = args["podcastid"]
		cur.execute("INSERT INTO subscriptions(userid, podcastid) VALUES (%s,%s);", (userID, podcastID))	#inserting subscription
		conn.commit()
		df.close_conn(conn, cur)
		return {'data' : "subscription successful"}, 200

	@token_required
	def delete(self):
		conn, cur = df.get_conn()
		userID = get_user_id()
		parser = reqparse.RequestParser(bundle_errors=True)
		parser.add_argument('podcastid', type=str, location="json")
		args = parser.parse_args()
		podcastID = args["podcastid"]
		cur.execute("DELETE FROM subscriptions WHERE userid = %s AND podcastid = %s;", (userID, podcastID))
		conn.commit()
		df.close_conn(conn,cur)
		return {"data" : "subscription deleted"}, 200
