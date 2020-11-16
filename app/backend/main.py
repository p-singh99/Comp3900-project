from flask import Flask, jsonify, request, make_response
from flask_restful import Api, Resource, reqparse
from flask_cors import CORS, cross_origin
from SemaThreadPool import SemaThreadPool
import dbfunctions
import os

app = Flask(__name__)
api = Api(app)
CORS(app)
api.init_app(app)

conn_pool = None
if os.environ.get("BROJOGAN_USE_LOCAL") == "1":
    conn_pool = SemaThreadPool(1,50,dbname="ultracast")
else:
    conn_pool = SemaThreadPool(1, 50,\
             dbname="ultracast", user="brojogan", password="GbB8j6Op", host="polybius.bowdens.me", port=5432)


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
		thread = threading.Thread(target=update_rss, args=(rssfeed, df.conn_pool), daemon=True)
		thread.start()
		return {"xml": xml, "id": id, "subscription": flag, "subscribers": subscribers, "rating": rating}, 200

class Subscriptions(Resource):
	@token_required
	def get(self):
		conn, cur = df.get_conn()
		uid = get_user_id(cur)
		cur.execute("SELECT p.title, p.author, p.description, p.id, r.rating, p.thumbnail FROM podcasts p, ratingsview r, subscriptions s \
			WHERE s.podcastId = p.id and s.userID = %s and r.id = p.id;", (uid,))
		podcasts = cur.fetchall()
		results = []
		for p in podcasts:
			cur.execute("select count(podcastId) FROM subscriptions where podcastId = %s GROUP BY podcastId;", (p[3],))
			subscribers = cur.fetchone()
			title = p[0]
			author = p[1]
			description = p[2]
			pID = p[3]
			rating = f"{p[4]:.1f}"
			thumbnail = p[5]
			results.append({"subscribers" : subscribers, "title" : title, "author" : author, "description" : description, "pid" : pID, "rating": rating, "thumbnail": thumbnail})
		df.close_conn(conn, cur)
		return results, 200

	@token_required
	def post(self):
		conn, cur = df.get_conn()
		userID = get_user_id(cur)
		parser = reqparse.RequestParser(bundle_errors=True)
		parser.add_argument('podcastid', type=str, location="json")
		args = parser.parse_args()
		podcastID = args["podcastid"]
		cur.execute("INSERT INTO subscriptions(userid, podcastid) VALUES (%s,%s);", (userID, podcastID))
		conn.commit()
		df.close_conn(conn, cur)
		return {'data' : "subscription successful"}, 200
	
class DeleteSubscription(Resource):
	@token_required
	def delete(self, podcastId):
		conn, cur = df.get_conn()
		userID = get_user_id(cur)
		cur.execute("DELETE FROM subscriptions WHERE userid = %s AND podcastid = %s;", (userID, podcastId))
		conn.commit()
		df.close_conn(conn,cur)
		return {"data" : "subscription deleted"}, 200

class History(Resource):
	@token_required
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
		user_id = get_user_id(cur)
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
		# print(eps)
		# change to episodes
		jsoneps = [{"pid" : ep[0], "xml": ep[1], "episodeguid": ep[2], "listenDate": ep[3].timestamp(), "timestamp": ep[4]} for ep in eps]
		df.close_conn(conn, cur)
		return jsonify(history=jsoneps, numPages=total_pages if id == 1  else '', status=200)

class Listens(Resource):
	@token_required
	def get(self, podcastId):
		conn, cur = df.get_conn()
		user_id = get_user_id(cur)
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

	@token_required
	def put(self, podcastId):
		conn, cur = df.get_conn()
		user_id = get_user_id(cur)
		timestamp = request.json.get("time")
		episodeGuid = request.json.get("episodeGuid")
		duration = request.json.get("duration")
		print("request.json is {}".format(request.json))
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

class ManyListens(Resource):
	@token_required
	def get(self, podcastId):
		conn, cur = df.get_conn()
		user_id = get_user_id(cur)
		cur.execute("""
			select episodeGuid, listenDate, timestamp, complete
			from listens where userid=%s and podcastid=%s
		""",
		(user_id, podcastId))
		res = cur.fetchall()
		df.close_conn(conn,cur)
		jsonready = [{
			"episodeGuid": x[0],
			"listenDate": str(x[1]),
			"timestamp": x[2],
			"complete": x[3]
		} for x in res]
		print("got res")
		print(jsonready)
		return jsonready, 200

class Recommendations(Resource):
	@token_required
	def get(self):
		conn, cur = df.get_conn()
		user_id = get_user_id(cur)
		recs = []
		cur.execute("select distinct * from recommendations(%s)", (user_id,))
		results = cur.fetchall()
		recs = [{"title": i[0], "thumbnail": i[1], "id": i[2], "subs": i[3], "eps": i[4], "rating": f"{i[5]:.1f}"} for i in results]
		df.close_conn(conn,cur)
		return {"recommendations" : recs}

class Notifications(Resource):
	@token_required
	def get(self):
		conn, cur = df.get_conn()
		user_id=get_user_id(cur)
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
			thread = threading.Thread(target=update_rss, args=(sp, df.conn_pool), daemon=True)
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
		for result in results:
			print(result)
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


class Notification(Resource):
	@token_required
	def delete(self, notificationId):
		conn,cur = df.get_conn()
		user_id=get_user_id(cur)
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
		user_id = get_user_id(cur)
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

# not used
# class RejectRecommendations(Resource):
# 	@token_required
# 	def put(self, id):
# 		conn, cur = df.get_conn()
# 		user_id = get_user_id(cur)
# 		cur.execute("INSERT INTO rejectedrecommendations (userid, podcastid) VALUES (%s, %s)", (user_id, id))
# 		conn.commit()
# 		df.close_conn(conn,cur)

class Ratings(Resource):
	def get(self, id):
		conn, cur = df.get_conn()
		user_id = get_user_id(cur)
		cur.execute("SELECT rating FROM podcastratings WHERE podcastid=%s and userid=%s", (id, user_id))
		res = cur.fetchone()
		rating = res[0] if res else None
		df.close_conn(conn, cur)
		return {"rating": rating}, 200

	def put(self,id):
		conn, cur = df.get_conn()
		user_id = get_user_id(cur)
		# get ratings limited to 1 to 5
		parser = reqparse.RequestParser()
		parser.add_argument('rating', type=int, required=True, choices=(1,2,3,4,5), help="Rating not valid", location="json")
		args = parser.parse_args()
		#check if already rated
		cur.execute("SELECT rating FROM podcastratings where userid=%s and podcastid=%s", (user_id, id))
		if cur.fetchone():
			cur.execute("UPDATE podcastratings SET rating=%s WHERE userid=%s and podcastid=%s", (args["rating"], user_id, id))
		else:
			cur.execute("INSERT INTO podcastratings (userid, podcastid, rating) VALUES (%s, %s, %s)", (user_id, id, args["rating"]))
		conn.commit()
		return {"success": "added"}
	
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
			#print({"id": i[0], "title": i[1], "subs": i[2], "thumbnail": i[3], "rating": f"{i[4]:.1f}", "eps":eps})
		cur.execute("SELECT p.id, t.title, p.count, t.thumbnail, r.rating FROM podcastsubscribers p, podcasts t, ratingsview r\
			where p.id = t.id and t.id=r.id ORDER BY r.rating DESC Limit 10")
		res = cur.fetchall()
		# return list of top 10 rated podcasts else empty list if no results
		for i in res:
			cur.execute("select title from episodes where podcastid=%s group by title, pubdate::timestamp order by pubdate::timestamp desc limit 30", (i[0],))
			eps = cur.fetchall()
			top_rated.append({"id": i[0], "title": i[1], "subs": i[2], "thumbnail": i[3], "rating": f"{i[4]:.1f}", "eps":eps})
		# for i in top_rated:
		# 	print(i['id'])
		print("finished")
		df.close_conn(conn,cur)
		return {"topSubbed": top_subbed, "topRated": top_rated}, 200
app.config['SECRET_KEY'] = 'secret_key'

from resources.notification import Notification
from resources.notifications import Notifications
from resources.bestpodcasts import BestPodcasts
from resources.history import History
from resources.listens import Listens
from resources.login import Login
from resources.manylistens import ManyListens
from resources.podcast import Podcast
from resources.podcasts import Podcasts
from resources.protected import Protected
from resources.ratings import Ratings
from resources.recommendations import Recommendations
from resources.self import Self
from resources.settings import Settings
from resources.subscriptionpanel import SubscriptionPanel
from resources.subscriptions import Subscriptions
from resources.users import Users
from resources.deletesubscription import DeleteSubscription

# auth
api.add_resource(Protected, "/protected")
api.add_resource(Login, "/login")
api.add_resource(Users, "/users")

# public
api.add_resource(Podcasts, "/podcasts")
api.add_resource(Podcast, "/podcasts/<int:id>")
api.add_resource(BestPodcasts, "/top-podcasts")

# user-specific
api.add_resource(Settings, "/users/self/settings")
api.add_resource(Self, "/users/self")
api.add_resource(Recommendations, "/users/self/recommendations")
api.add_resource(Subscriptions, "/users/self/subscriptions")
api.add_resource(SubscriptionPanel, "/users/self/subscription-panel")
api.add_resource(History, "/users/self/history/<int:id>")
api.add_resource(Notifications, "/users/self/notifications")
api.add_resource(DeleteSubscription, "/users/self/subscriptions/<podcastId>")
api.add_resource(Notification, "/users/self/notification/<int:notificationId>")
api.add_resource(Listens, "/users/self/podcasts/<int:podcastId>/episodes/time")
api.add_resource(ManyListens, "/users/self/podcasts/<int:podcastId>/time")
api.add_resource(Ratings, "/users/self/ratings/<int:id>")
#api.init_app(app)

if __name__ == '__main__':
	app.run(debug=True)