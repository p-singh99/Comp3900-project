from flask import Flask, jsonify, request
from flask_restful import Resource
from functools import wraps
from flask_restful import Api, Resource, reqparse
import user_functions as uf
import dbfunctions as df
import math

class Listens(Resource):
	@uf.token_required
	def get(self, podcastId):
		conn, cur = df.get_conn()
		user_id = uf.get_user_id()
		episodeGuid = request.json.get("episodeGuid")
		if episodeGuid is None:
			df.close_conn(conn, cur)
			return {"error": "episodeGuid not included"}, 400

		cur.execute("""
			SELECT timestamp, complete from listens where
			podcastId=%s and episodeGuid=%s and userId=%s
		""",
		(podcastId, episodeGuid, user_id))
		res = cur.fetchone()
		df.close_conn(conn, cur)
		if res is None:
			return {"error":"invalid podcastId or episodeGuid"}, 400
		return {"time": int(res[0]), "complete": res[1]}, 200

	@uf.token_required
	def put(self, podcastId):
		conn, cur = df.get_conn()
		user_id = uf.get_user_id()
		timestamp = request.json.get("time")
		episodeGuid = request.json.get("episodeGuid")
		duration = request.json.get("duration")
		if timestamp is None:
			df.close_conn(conn,cur)
			return {"error": "timestamp not included"}, 400
		if not isinstance(timestamp, int):
			df.close_conn(conn,cur)
			return {"error": "timestamp must be an integer"}, 400
		if episodeGuid is None:
			df.close_conn(conn,cur)
			return {"error": "episodeGuid not included"}, 400
		if duration is None:
			df.close_conn(conn,cur)
			return {"error": "duration is not included"}, 400
		# calculate if the episode is complete. we consider complete as being 95% of the way though the podcast
		# sometimes if the front end can't get the duration it sends it as -1. 
		# 	(I think because it sends a request before the metadata has loaded, which shouldn't happen)
		# If the duration is less than 0 we'll treat it as not complete
		complete = (timestamp >= 0.95 * duration) if duration >= 0 else False
		
		# if the duration is greater than 0 we'll try to update the episode to include the duration
		if (duration > 0):
			try:
				cur.execute("""
					update episodes 
					set duration=%s
					where guid=%s and podcastId=%s
				""",
				(duration, episodeGuid, podcastId))
			except Exception as e:
				df.close_conn(conn,cur)
				return {"error": "Failed to update episodes, probably because the episode does not exist:\n{}".format(str(e))}, 400

		cur.execute("""
			INSERT INTO listens (userId, podcastId, episodeGuid, listenDate, timestamp, complete)
			values (%s, %s, %s, now(), %s, %s)
			ON CONFLICT ON CONSTRAINT listens_pkey DO UPDATE set listenDate=now(), timestamp=%s, complete=%s;
		""",
		(user_id, podcastId, episodeGuid, timestamp, complete, timestamp, complete))
		conn.commit()
		df.close_conn(conn,cur)
		return {}, 200