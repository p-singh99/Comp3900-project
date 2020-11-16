from flask import request
from flask_restful import Resource
from functools import wraps
import datetime
import user_functions as uf
import dbfunctions as df

class Podcasts(Resource):
	def get(self):
		search = request.args.get('search_query')
		if search is None:
			return {"error": "Bad Request"}, 400
		conn, cur = df.get_conn()
		# adding search query to db
		user_id = uf.get_user_id()
		if user_id:
			cur.execute("insert into searchqueries (userid, query, searchdate) values (%s, %s, %s)",(user_id, search, datetime.datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")))
		conn.commit()
		startNum = request.args.get('offset')
		limitNum = request.args.get('limit')

		cur.execute("""SELECT count(s.podcastid), v.title, v.author, v.description, v.id, v.thumbnail, rv.rating
	     			FROM   searchvector v
	     			FULL OUTER JOIN Subscriptions s ON s.podcastId = v.id
		                LEFT JOIN ratingsview rv ON v.id = rv.id
	     			WHERE  v.vector @@ plainto_tsquery(%s)
	     			GROUP BY  (s.podcastid, v.title, v.author, v.description, v.id, v.vector, v.thumbnail, rv.rating)
				ORDER BY  ts_rank(v.vector, plainto_tsquery(%s)) desc;
				""",
				(search,search))
		podcasts = cur.fetchall()	# this query grabs the podcasts that directly match the search within the title or author names
		cur.execute("""SELECT DISTINCT p.id, p.title, p.author, p.description, ps.count, p.thumbnail, rv.rating
		               FROM   podcasts p
		               LEFT JOIN podcastcategories t
		                      ON t.podcastid = p.id
		               LEFT JOIN categories c
		                      ON t.categoryid = c.id
		               LEFT JOIN podcastsubscribers ps
		                      ON ps.id = p.id
		               LEFT JOIN ratingsview rv
		                      ON p.id = rv.id
		               WHERE  to_tsvector(c.name) @@ plainto_tsquery(%s) and p.id not in (select podcastid from search(%s));
		            """,
		            (search,search))
		categories = cur.fetchall()	# this query grabs the podcasts which match the searched text with any categories an returns those that do not clash with the previous query
		results = []
		# grabbing the results and putting them into json formatting
		for p in podcasts:
			subscribers = p[0]
			title = p[1]
			author = p[2]
			description = p[3]
			pID = p[4]
			thumbnail = p[5]
			rating = f"{p[6]:.1f}"
			results.append({"subscribers" : subscribers, "title" : title, "author" : author, "description" : description, "pid" : pID, "thumbnail" : thumbnail, "rating" : rating})
		for c in categories:
			results.append({"subscribers" : c[4], "title" : c[1], "author" : c[2], "description" : c[3], "pid" : c[0], "thumbnail" : c[5], "rating" : f"{c[6]:.1f}"})
		df.close_conn(conn, cur)
		return results, 200
