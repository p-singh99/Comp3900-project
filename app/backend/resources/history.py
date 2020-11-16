from flask import Flask, jsonify
from flask_restful import Resource
from functools import wraps
from flask_restful import Api, Resource, reqparse
import user_functions as uf
import dbfunctions as df
import math

class History(Resource):
	@uf.token_required
	def get(self, id):
		# id is pageNum
		parser = reqparse.RequestParser()
		parser.add_argument('limit', type=int, required=False, location="args")
		args = parser.parse_args()
		# get user defined limit or set to default
		limit = args['limit'] if args['limit'] is not None else 12
		if limit <= 0 or id <= 0:
			return {"error": "bad request"}, 400
		offset = (id - 1)*limit 
		conn, cur = df.get_conn()
		user_id = uf.get_user_id()
		# if first page get all results to determine amount of pages
		if id == 1:
			cur.execute("SELECT p.id, p.xml, l.episodeguid, l.listenDate, l.timestamp FROM listens l, podcasts p where l.userid=%s and \
			p.id = l.podcastid ORDER BY l.listenDate DESC",(user_id,))
			# calculate total pages based on limit
			total_pages = math.ceil( cur.rowcount / limit )
		else:
			cur.execute("SELECT p.id, p.xml, l.episodeguid, l.listenDate, l.timestamp FROM listens l, podcasts p where l.userid=%s and \
				p.id = l.podcastid ORDER BY l.listenDate DESC LIMIT %s OFFSET %s", (user_id, limit, offset))
		eps = cur.fetchmany(limit)
		# change to episodes
		jsoneps = [{"pid" : ep[0], "xml": ep[1], "episodeguid": ep[2], "listenDate": ep[3].timestamp(), "timestamp": ep[4]} for ep in eps]
		df.close_conn(conn, cur)
		return jsonify(history=jsoneps, numPages=total_pages if id == 1  else '', status=200)