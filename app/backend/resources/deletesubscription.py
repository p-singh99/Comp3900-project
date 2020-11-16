from flask import Flask, jsonify, request
from flask_restful import Resource
from functools import wraps
from flask_restful import Api, Resource, reqparse
from user_functions import token_required, get_user_id
import dbfunctions as df

# deletes subscription from the user's subscription
class DeleteSubscription(Resource):
	@token_required
	def delete(self, podcastId):
		conn, cur = df.get_conn()
		userID = get_user_id()
		cur.execute("DELETE FROM subscriptions WHERE userid = %s AND podcastid = %s;", (userID, podcastId))
		conn.commit()
		df.close_conn(conn,cur)
		return {"data" : "subscription deleted"}, 200
