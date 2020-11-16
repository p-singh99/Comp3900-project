from flask_restful import Resource
from functools import wraps
import user_functions as uf
import dbfunctions as df
import re

# Subscription panel which grabs the most recent episode from a subscription and posts it on the homepage
class SubscriptionPanel(Resource):
	def get(self):
		conn,cur = df.get_conn()
		uid = uf.get_user_id()
		cur.execute("""SELECT p.title, p.xml, p.id
		               FROM   podcasts p
		               FULL OUTER JOIN   subscriptions s
		               on s.podcastId = p.id
		               WHERE  s.userID = %s;
		            """, (uid,))
		podcasts = cur.fetchall()			# grabs the subscribed podcast for the user
		results = []
		for p in podcasts:
			# print(p[1])
			search = re.search('<guid.*>(.*)</guid>', p[1])		#This Regex searchs for the guid
			guid = search.group(1)
			cur.execute("SELECT complete FROM Listens where episodeGuid =%s AND userId = %s;", (guid, uid))
			res = cur.fetchone()
			if res is None or res[0] == False: # if the episode has been completely watched then we don't add it to the subscription panel
				title = p[0]
				xml = p[1]
				pid = p[2]
				results.append({"title":title, "xml":xml, "pid":pid, "guid":guid})
		df.close_conn(conn, cur)
		return results, 200
