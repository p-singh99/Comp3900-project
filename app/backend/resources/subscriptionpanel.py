from flask_restful import Resource
from functools import wraps
import backend.user_functions as uf
import backend.dbfunctions as df
import re

class SubscriptionPanel(Resource):
	def get(self):
		conn,cur = df.get_conn()
		uid = uf.get_user_id()
		print(uid)
		cur.execute("""SELECT p.title, p.xml, p.id
		               FROM   podcasts p
		               FULL OUTER JOIN   subscriptions s
		               on s.podcastId = p.id
		               WHERE  s.userID = %s;
		            """, (uid,))
		podcasts = cur.fetchall()
		results = []
		# s = re.search('<guid.*>(.*)</guid>', podcasts[3][1])
		# print(s)
		for p in podcasts:
			# print(p[1])
			search = re.search('<guid.*>(.*)</guid>', p[1])
			print(search)
			if search:
				guid = search.group(1)
				cur.execute("SELECT complete FROM Listens where episodeGuid =%s AND userId = %s;", (guid, uid))
			title = p[0]
			xml = p[1]
			pid = p[2]
			results.append({"title":title, "xml":xml, "pid":pid, "guid":guid})
		df.close_conn(conn, cur)
		return results, 200