from flask import request
from flask_restful import Resource
from functools import wraps
import datetime
import jwt
import bcrypt
from flask_restful import Api, Resource, reqparse
import user_functions as uf
import dbfunctions as df
from main import conn_pool
import threading
from rss import update_rss

class Notifications(Resource):
	@uf.token_required
	def get(self):
		conn, cur = df.get_conn()
		user_id=uf.get_user_id()
		cur.execute("""
		select p.rssfeed from
		subscriptions s
		join podcasts p on s.podcastId=p.id
		where s.userId = %s
		""", (user_id,))
		results = cur.fetchall()
		subscribedPodcasts = []
		if results:
			subscribedPodcasts = [x[0] for x in results]
		for sp in subscribedPodcasts:
			thread = threading.Thread(target=update_rss, args=(sp, conn_pool), daemon=True)
			thread.start()

		cur.execute("""
		select p.title, p.id, e.title, e.created, e.guid, u.status, u.id from
		notifications u
		join episodes e on u.episodeguid=e.guid
		join podcasts p on e.podcastid=p.id
		where u.userid=%s
		and (u.status='read' or u.status='unread')
		order by e.created desc
		""", (user_id,))
		results = cur.fetchall()
		df.close_conn(conn,cur)
		if results is None:
			return {}, 200
		json = [{
			"podcastTitle": x[0],
			"podcastId":    x[1],
			"episodeTitle": x[2],
			"dateCreated":  str(x[3]),
			"episodeGuid":  x[4],
			"status":       x[5],
			"id": 		x[6]
		} for x in results]
		return json, 200