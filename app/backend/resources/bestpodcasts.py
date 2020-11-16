from flask import request
from flask_restful import Resource
from functools import wraps
import datetime
import jwt
import bcrypt
from flask_restful import Api, Resource, reqparse
import user_functions as uf
import dbfunctions as df

class BestPodcasts(Resource):
	def get(self):
		conn, cur = df.get_conn()
		cur.execute("SELECT p.id, t.title, p.count, t.thumbnail, r.rating FROM podcastsubscribers p, podcasts t, ratingsview r\
			where p.id = t.id and t.id=r.id ORDER BY p.count DESC Limit 10")
		# return list of top 10 subbed podcasts else empty list if no results
		res = cur.fetchall()
		top_subbed = []
		top_rated = []
		for i in res:
			cur.execute("select title from episodes where podcastid=%s group by title, pubdate::timestamp order by pubdate::timestamp desc limit 30", (i[0],))
			eps = cur.fetchall()
			top_subbed.append({"id": i[0], "title": i[1], "subs": i[2], "thumbnail": i[3], "rating": f"{i[4]:.1f}", "eps":eps})
		cur.execute("SELECT p.id, t.title, p.count, t.thumbnail, r.rating FROM podcastsubscribers p, podcasts t, ratingsview r\
			where p.id = t.id and t.id=r.id ORDER BY r.rating DESC Limit 10")
		res = cur.fetchall()
		# return list of top 10 rated podcasts else empty list if no results
		for i in res:
			cur.execute("select title from episodes where podcastid=%s group by title, pubdate::timestamp order by pubdate::timestamp desc limit 30", (i[0],))
			eps = cur.fetchall()
			top_rated.append({"id": i[0], "title": i[1], "subs": i[2], "thumbnail": i[3], "rating": f"{i[4]:.1f}", "eps":eps})
		# for i in top_rated:
		df.close_conn(conn,cur)
		return {"topSubbed": top_subbed, "topRated": top_rated}, 200