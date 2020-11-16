from flask import request
from flask_restful import Resource
#from functools import wraps
#import datetime
#import jwt
#import bcrypt
#from flask_restful import Api, Resource, reqparse
from user_functions import token_required, get_user_id
import dbfunctions as df
from rss import update_rss

class Notification(Resource):
	@token_required
	def delete(self, notificationId):
		conn,cur = df.get_conn()
		user_id=get_user_id()
		cur.execute("""
		update notifications
		set status='dismissed'
		where id=%s and userId=%s
		returning id
		""", (notificationId, user_id))
		results = cur.fetchall()
		if len(results) > 1:
			conn.rollback()
			df.close_conn(conn,cur)
			return {"data": "unexpectedly deleted more than 1 notification. rolling back"}, 500
		conn.commit()
		df.close_conn(conn,cur)
		if len(results) == 0:
			return {"data": "No notification associated with id {} and userId {}".format(notificationId, user_id)}, 404
		return {}, 200


	@token_required
	def put(self, notificationId):
		status = request.json.get("status")
		if status is None:
			return {"data": "must include status field"}, 400
		if not isinstance(status, str) and status not in ['read', 'unread', 'dismissed']:
			return {"data": "status must be one of read, undread, or dismissed"}, 400
		conn, cur = df.get_conn()
		user_id = get_user_id()
		cur.execute("""
		update Notifications set status=%s
		where id=%s and userid=%s
		returning id
		""", (status, notificationId, user_id))
		results = cur.fetchall()
		if len(results) > 1:
			conn.rollback()
			df.close_conn(conn,cur)
			return {"data": "unexpectedly modified more than 1 notification. rolling back"}, 500
		conn.commit()
		df.close_conn(conn,cur)
		if len(results) == 0:
			return {"data": "No notification associated with id {} and userId {}".format(notificationId, user_id)}, 404
		return {}, 200