from flask import Flask, jsonify, request, make_response
from flask_restful import Api, Resource, reqparse
from flask_cors import CORS, cross_origin
import psycopg2
from psycopg2 import pool
import jwt
import bcrypt
import datetime
from functools import wraps
import requests
import feedparser
import urllib.parse
import re
from SemaThreadPool import SemaThreadPool
import math
import dbfunctions as df

app = Flask(__name__)
api = Api(app)
CORS(app)

#CHANGE SECRET KEY
app.config['SECRET_KEY'] = 'secret_key'
# # remote
# conn_pool = SemaThreadPool(1, 50,\
# 	 dbname="ultracast", user="brojogan", password="GbB8j6Op", host="polybius.bowdens.me", port=5432)
# # local
# #conn_pool = SemaThreadPool(1, 50,\
# #	 dbname="ultracast")

# def get_conn():
# 	conn = conn_pool.getconn()
# 	cur = conn.cursor()
# 	return conn, cur

# def close_conn(conn, cur):
# 	cur.close()
# 	conn_pool.putconn(conn)

def create_token(username):
	# implement some kind of token refreshing scheme
	token = jwt.encode({'user' : username, 'exp' : datetime.datetime.utcnow() + datetime.timedelta(minutes=60)}, app.config['SECRET_KEY'])
	return token.decode('UTF-8')

def token_required(f):
	@wraps(f)
	def decorated(*args, **kwargs):
		token = request.headers.get('token')
		if not token:
			return {'error' : 'token is missing'}, 401
		try:
			data = jwt.decode(token, app.config['SECRET_KEY'])
		except:
			return {'error' : 'token is invalid'}, 401
		return f(*args, **kwargs)
	return decorated

def get_user_id(cur):
	token = request.headers.get('token')
	if token:
		try:
			data = jwt.decode(token, app.config['SECRET_KEY'])
			cur.execute("SELECT id FROM users WHERE username =%s or email = %s", (data['user'], data['user']))
		except:
			return None
		return cur.fetchone()[0]
	return None

# class Unprotected(Resource):
# 	def get(self):
# 		return {'message': 'anyone'}, 200

class Protected(Resource):
	@token_required
	def get(self):
		return {'message': 'not anyone'}, 200

class SubscriptionPanel(Resource):
	def get(self):
		conn,cur = df.get_conn()
		uid = get_user_id(cur)
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
			# bool = cur.fetchone()[0]
			if cur.fetchone() == None:
				continue
			title = p[0]
			xml = p[1]
			pid = p[2]
			results.append({"title":title, "xml":xml, "pid":pid, "guid":guid})
		df.close_conn(conn, cur)
		return results, 200

class Login(Resource):
	def post(self):
		username = request.form.get('username').lower()
		password = request.form.get('password')
		# Check if username or email
		conn, cur = df.get_conn()
		# Check if username exists
		cur.execute("SELECT username, hashedpassword FROM users WHERE username=%s OR email=%s", (username, username))
		res = cur.fetchone()
		df.close_conn(conn, cur)
		if res:
			username = res[0].strip()
			pw = res[1].strip()
			pw = pw.encode('UTF-8')
			password = request.form.get('password')
			if bcrypt.checkpw(password.encode('UTF-8'), pw):
				return {'token' : create_token(username), 'user': username}, 200
		return {"data" : "Login Failed"}, 401


class Users(Resource):
	def post(self):
		conn, cur = df.get_conn()
		username = request.form.get('username').lower()
		email = request.form.get('email').lower()
		passw = request.form.get('password')
		pw = passw.encode('UTF-8')
		hashed = bcrypt.hashpw(pw, bcrypt.gensalt())
		error = False
		error_msg = []
		# check if username exists in database
		cur.execute("SELECT * FROM users WHERE username=%s",(username,))
		if cur.fetchone():
			error = True
			error_msg.append("Username already exists")
		# check if email exists in database
		cur.execute("SELECT * FROM users WHERE email=%s", (email,))
		if cur.fetchone():
			error = True
			error_msg.append("Email already exists")
		if error:
			cur.close()
			return {"error": error_msg}, 409
		cur.execute("insert into users (username, email, hashedpassword) values (%s, %s, %s)", (username, email, hashed.decode("UTF-8")))
		conn.commit()
		df.close_conn(conn, cur)
		# return token
		return {'token' : create_token(username), 'user': username}, 201


class Podcasts(Resource):
	def get(self):
		# todo: try catch this
		search = request.args.get('search_query')
		if search is None:
			return {"error": "Bad Request"}, 400
		# todo: try catch this
		conn, cur = df.get_conn()
		# add search query to db
		user_id = get_user_id(cur)
		if user_id:
			cur.execute("insert into searchqueries (userid, query, searchdate) values (%s, %s, %s)",(user_id, search, datetime.datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")))
		conn.commit()
		startNum = request.args.get('offset')
		limitNum = request.args.get('limit')

		cur.execute("""SELECT count(s.podcastid), v.title, v.author, v.description, v.id
	     			FROM   searchvector v
	     			FULL OUTER JOIN Subscriptions s ON s.podcastId = v.id
	     			WHERE  v.vector @@ plainto_tsquery(%s)
	     			GROUP BY  (s.podcastid, v.title, v.author, v.description, v.id, v.vector)
				ORDER BY  ts_rank(v.vector, plainto_tsquery(%s)) desc;
				""",
				(search,search))
		podcasts = cur.fetchall()
		cur.execute("""SELECT DISTINCT p.id, p.title, p.author, p.description, ps.count
		               FROM   podcasts p
		               LEFT JOIN podcastcategories t
		                      ON t.podcastid = p.id
		               LEFT JOIN categories c
		                      ON t.categoryid = c.id
		               LEFT JOIN podcastsubscribers ps
		                      ON ps.id = p.id
		               WHERE  to_tsvector(c.name) @@ plainto_tsquery(%s) and p.id not in (select podcastid from search(%s));
		            """,
		            (search,search))
		categories = cur.fetchall()
		results = []
		for p in podcasts:
			subscribers = p[0]
			title = p[1]
			author = p[2]
			description = p[3]
			pID = p[4]
			results.append({"subscribers" : subscribers, "title" : title, "author" : author, "description" : description, "pid" : pID})
		for c in categories:
			results.append({"subscribers" : c[4], "title" : c[1], "author" : c[2], "description" : c[3], "pid" : c[0]})
		df.close_conn(conn, cur)
		return results, 200



class Settings(Resource):
	@token_required
	def get(self):
		conn, cur = df.get_conn()
		data = jwt.decode(request.headers['token'], app.config['SECRET_KEY'])
		username = data['user']
		cur.execute("SELECT email FROM users WHERE username=%s", (username,))
		email = cur.fetchone()[0]
		df.close_conn(conn, cur)
		return {"email" : email}

	@token_required
	def put(self):
		data = jwt.decode(request.headers['token'], app.config['SECRET_KEY'])
		username = data['user']
		conn, cur = df.get_conn()
		parser = reqparse.RequestParser(bundle_errors=True)
		parser.add_argument('oldpassword', type=str, required=True, help="Need old password", location="json")
		parser.add_argument('newpassword', type=str, location="json")
		parser.add_argument('newemail', type=str, location="json")
		args = parser.parse_args()
		hashedpassword = ""
		# check current password
		cur.execute("SELECT hashedpassword FROM users WHERE username=%s", (username))
		old_pw = cur.fetchone()[0].strip()
		if bcrypt.checkpw(args["oldpassword"].encode('UTF-8'), old_pw.encode('utf-8')):
			if args["newpassword"]:
				if args["oldpassword"] != args["newpassword"]:
					# change password
					password = args["newpassword"]
					password = password.encode('UTF-8')
					hashedpassword = bcrypt.hashpw(password, bcrypt.gensalt())
			if args['newemail']:
				# change email
				cur.execute("SELECT email FROM users where email=%s", (args['newemail']))
				if cur.fetchone():
					cur.execute("SELECT email FROM users where email=%s and username=%s", (args['newemail'], data['user']))
					if not cur.fetchone():
						df.close_conn(conn, cur)
						return {"error": "Email already exists"}, 400

				cur.execute("UPDATE users SET email=%s WHERE username=%s OR email=%s", (args['newemail'], username, username))
			if hashedpassword:
				cur.execute("UPDATE users SET hashedpassword=%s WHERE username=%s OR email = %s", (hashedpassword.decode('UTF-8'), username, username))
			conn.commit()
			df.close_conn(conn, cur)
			return {"data" : "success"}, 200
		df.close_conn(conn,cur)
		return {"error" : "wrong password"}, 400

class Self(Resource):
	@token_required
	def delete(self):
		conn, cur = df.get_conn()
		user_id = get_user_id(cur)
		parser = reqparse.RequestParser(bundle_errors=True)
		parser.add_argument('password', type=str, required=True, help="Need old password", location="json")
		args = parser.parse_args()
		cur.execute("SELECT hashedpassword FROM users WHERE id=%s", (user_id,))
		old_pw = cur.fetchone()[0].strip()
		if bcrypt.checkpw(args["password"].encode('UTF-8'), old_pw.encode('utf-8')):
			# delete from users
			cur.execute("DELETE FROM users WHERE id=%s", (user_id,))
			# delete all subscriptions
			cur.execute("DELETE FROM subscriptions WHERE userId=%s", (user_id,))
			# delete podcast account
			cur.execute("DELETE FROM podcastratings WHERE userId=%s", (user_id,))
			# delete episode ratings
			cur.execute("DELETE FROM episoderatings WHERE userId=%s", (user_id,))
			# delete listens
			cur.execute("DELETE FROM listens WHERE userId=%s", (user_id,))
			# delete seach queries
			cur.execute("DELETE FROM searchqueries WHERE userId=%s", (user_id,))
			# delete rejected recommendations
			cur.execute("DELETE FROM rejectedrecommendations WHERE userId=%s", (user_id,))
			conn.commit()
			df.close_conn(conn,cur)
			return {"data" : "account deleted"}, 200
		else:
			df.close_conn(conn,cur)
			return {"error" : "wrong password"}, 400


class Podcast(Resource):
	def get(self, id):
		conn, cur = df.get_conn()
		uid = get_user_id(cur)
		cur.execute("SELECT * FROM subscriptions WHERE userid = %s AND podcastid = %s;", (uid, id))
		flag = False
		if cur.rowcount != 0:
			flag = True
		cur.execute("SELECT xml, id FROM Podcasts WHERE id=(%s)", (id,))
		res = cur.fetchone()
		if res is None:
			return {}, 404
		xml = res[0]
		id  = res[1]

		cur.execute("SELECT count(*) from subscriptions where podcastid=(%s)", (id,))
		res = cur.fetchone()
		subscribers = 0
		if res is not None:
			subscribers = res[0]
		cur.execute("SELECT coalesce from ratingsview where id=%s", (id,))
		
		res = cur.fetchone()
		if res:
			# rating = int(round(res[0],1))
			rating = f"{res[0]:.1f}"
		print(rating)
		df.close_conn(conn,cur)
		return {"xml": xml, "id": id, "subscription": flag, "subscribers": subscribers, "rating": rating}, 200


class Subscriptions(Resource):
	@token_required
	def get(self):
		conn, cur = df.get_conn()
		uid = get_user_id(cur)
		cur.execute("SELECT p.title, p.author, p.description, p.id, r.coalesce, p.thumbnail FROM podcasts p, ratingsview r, subscriptions s \
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
			#rating = p[4]
			# rating = int(round(p[4],1))
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

	@token_required
	def delete(self):
		conn, cur = df.get_conn()
		userID = get_user_id(cur)
		parser = reqparse.RequestParser(bundle_errors=True)
		parser.add_argument('podcastid', type=str, location="json")
		args = parser.parse_args()
		podcastID = args["podcastid"]
		cur.execute("DELETE FROM subscriptions WHERE userid = %s AND podcastid = %s;", (userID, podcastID))
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
		limit = args['limit'] if args['limit'] is not None else 12
		print(limit)
		if limit <= 0 or id <= 0:
			return {"error": "bad request"}, 400
		offset = (id - 1)*limit 
		conn, cur = df.get_conn()
		user_id = get_user_id(cur)
		if id == 1:
			cur.execute("SELECT p.id, p.xml, l.episodeguid, l.listenDate, l.timestamp FROM listens l, podcasts p where l.userid=%s and \
			p.id = l.podcastid ORDER BY l.listenDate DESC",(user_id,))
			total_pages = math.ceil( cur.rowcount / limit )
		else:
			cur.execute("SELECT p.id, p.xml, l.episodeguid, l.listenDate, l.timestamp FROM listens l, podcasts p where l.userid=%s and \
				p.id = l.podcastid ORDER BY l.listenDate DESC LIMIT %s OFFSET %s", (user_id, limit, offset))
		eps = cur.fetchmany(limit)
		print(eps)
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
		complete = timestamp >= 0.95 * duration
		
		# we're touching episodes so insert new episode (if it doesn't already exist)
		cur.execute("""
			INSERT INTO episodes (podcastId, guid)
			values (%s, %s)
			ON CONFLICT DO NOTHING
		""",
		(podcastId, episodeGuid))

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
		[recs.append({"title": i[0], "thumbnail": i[1], "id": i[2], "subs": i[3], "eps": i[4], "rating": i[5]}) for i in results]
		df.close_conn(conn,cur)
		return {"recommendations" : recs}

class RejectRecommendations(Resource):
	@token_required
	def put(self, id):
		conn, cur = df.get_conn()
		user_id = get_user_id(cur)
		cur.execute("INSERT INTO rejectedrecommendations (userid, podcastid) VALUES (%s, %s)", (user_id, id))
		conn.commit()
		df.close_conn(conn,cur)
		
class Notifications(Resource):
	def get(self):
		conn, cur = df.get_conn()
		user_id = get_user_id(cur)
		cur.execute("select * from notifications where user='%s'", (user_id))
		df.close_conn(conn, cur)
		return {"notifications": cur.fetchall()}

class Ratings(Resource):
	def get(self, id):
		conn, cur = df.get_conn()
		user_id = get_user_id(cur)
		cur.execute("SELECT rating FROM podcastratings WHERE podcastid=%s and userid=%s", (id, user_id))
		# rating = cur.fetchone()[0] if cur.fetchone() else None
		res = cur.fetchone()
		rating = res[0] if res else None
		df.close_conn(conn, cur)
		return {"rating": rating}, 200

	def put(self,id):
		conn, cur = df.get_conn()
		user_id = get_user_id(cur)
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
		cur.execute("SELECT * FROM podcastsubscribers ORDER BY count DESC Limit 10")
		top_subbed = cur.fetchall()
		cur.execute("SELECT * FROM ratingsview ORDER BY rating DESC Limit 10")
		top_rated = cur.fetchall()
		df.close_conn(conn,cur)
		return {"topSubbed": top_subbed, "topRated": top_rated}, 200

# api.add_resource(Unprotected, "/unprotected")
# auth
api.add_resource(Protected, "/protected")
api.add_resource(Login, "/login")
api.add_resource(Users, "/users")

# public
api.add_resource(Podcasts, "/podcasts")
api.add_resource(Podcast, "/podcasts/<int:id>")
api.add_resource(BestPodcasts, "/top-podcasts")

# user-specific
api.add_resource(Settings, "/self/settings")
api.add_resource(Self, "/self")
api.add_resource(Recommendations, "/self/recommendations")
api.add_resource(Subscriptions, "/self/subscriptions")
api.add_resource(SubscriptionPanel, "/self/subscription-panel")
api.add_resource(History, "/self/history/<int:id>")
api.add_resource(Listens, "/self/podcasts/<int:podcastId>/episodes/time")
api.add_resource(ManyListens, "/self/podcasts/<int:podcastId>/time")
api.add_resource(Ratings, "/self/ratings/<int:id>")

if __name__ == '__main__':
	app.run(debug=True, threaded=True)
