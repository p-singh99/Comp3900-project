from flask import Flask, jsonify, request
from flask_restful import Resource
from functools import wraps
from flask_restful import Api, Resource, reqparse
import user_functions as uf
import dbfunctions as df
from main import conn_pool
import threading
from rss import update_rss

class Podcast(Resource):
	def get(self, id):
		conn, cur = df.get_conn()
		uid = uf.get_user_id()
		# uid = 'or 1=1#'
		cur.execute("SELECT * FROM subscriptions WHERE userid = %s AND podcastid = %s;", (uid, id))
		# print(cur.rowcount)
		flag = False
		if cur.rowcount != 0:
			flag = True
		cur.execute("SELECT xml, id, rssfeed FROM Podcasts WHERE id=(%s)", (id,))
		res = cur.fetchone()
		if res is None:
			return {}, 404
		xml = res[0]
		id  = res[1]
		rssfeed=res[2]

		cur.execute("SELECT count(*) from subscriptions where podcastid=(%s)", (id,))
		res = cur.fetchone()
		subscribers = 0
		if res is not None:
			subscribers = res[0]
		cur.execute("SELECT rating from ratingsview where id=%s", (id,))
		
		res = cur.fetchone()
		if res:
			# rating = int(round(res[0],1))
			rating = f"{res[0]:.1f}"
		print(rating)
		df.close_conn(conn,cur)
		thread = threading.Thread(target=update_rss, args=(rssfeed, conn_pool), daemon=True)
		thread.start()
		return {"xml": xml, "id": id, "subscription": flag, "subscribers": subscribers, "rating": rating}, 200