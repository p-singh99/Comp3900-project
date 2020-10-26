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


app = Flask(__name__)
api = Api(app)
CORS(app)

#CHANGE SECRET KEY
app.config['SECRET_KEY'] = 'secret_key'
conn_pool = psycopg2.pool.ThreadedConnectionPool(1, 3,\
	 dbname="ultracast", user="brojogan", password="GbB8j6Op", host="polybius.bowdens.me", port=5432)

def get_conn():
	conn = conn_pool.getconn()
	cur = conn.cursor()
	return conn, cur

def close_conn(conn, cur):
	cur.close()
	conn_pool.putconn(conn)

def create_token(username):
	token = jwt.encode({'user' : username, 'exp' : datetime.datetime.utcnow() + datetime.timedelta(minutes=20)}, app.config['SECRET_KEY'])
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
	token = request.headers['token']
	data = jwt.decode(token, app.config['SECRET_KEY'])
	cur.execute("SELECT id FROM users WHERE username ='%s' or email = '%s'" % (data['user'], data['user']))
	return cur.fetchone()[0]

class Unprotected(Resource):
	def get(self):
		return {'message': 'anyone'}, 200

class Protected(Resource):
	@token_required
	def get(self):
		return {'message': 'not anyone'}, 200

class Login(Resource):
	def post(self):
		username = request.form.get('username').lower()
		password = request.form.get('password')
		# Check if username or email
		conn, cur = get_conn()
		# Check if username exists
		cur.execute("SELECT username, hashedpassword FROM users WHERE username='%s' OR email='%s'" % (username, username))
		res = cur.fetchone()
		close_conn(conn, cur)
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
		conn, cur = get_conn()
		username = request.form.get('username').lower()
		email = request.form.get('email').lower()
		passw = request.form.get('password')
		pw = passw.encode('UTF-8')
		hashed = bcrypt.hashpw(pw, bcrypt.gensalt())
		error = False
		error_msg = []
		# check if username exists in database
		cur.execute("SELECT * FROM users WHERE username='%s'" % username)
		if cur.fetchone():
			error = True
			error_msg.append("Username already exists")
		# check if email exists in database
		cur.execute("SELECT * FROM users WHERE email='%s'" % email)
		if cur.fetchone():
			error = True
			error_msg.append("Email already exists")
		if error:
			cur.close()
			return {"error": error_msg}, 409
		cur.execute("insert into users (username, email, hashedpassword) values (%s, %s, %s)", (username, email, hashed.decode("UTF-8")))
		conn.commit()
		close_conn(conn, cur)
		# return token
		return {'token' : create_token(username), 'user': username}, 201


class Podcasts(Resource):
	def get(self):
		# todo: try catch this
		print(request.args)
		search = request.args.get('search_query')
		if search is None:
			return {"data": "Bad Request"}, 400
		# todo: try catch this
		conn, cur = get_conn()
		startNum = request.args.get('offset')
		limitNum = request.args.get('limit')

		cur.execute("""SELECT count(s.userid), v.title, v.author, v.description, v.id
	     			FROM   searchvector v
	     			FULL OUTER JOIN Subscriptions s ON s.podcastId = v.id
	     			WHERE  v.vector @@ plainto_tsquery(%s)
	     			GROUP BY  (s.userid, v.title, v.author, v.description, v.id, v.vector)
				ORDER BY  ts_rank(v.vector, plainto_tsquery(%s)) desc;
				""",
				(search,search)
	   		   )

		podcasts = cur.fetchall()
		cur.close()
		results = []
		for p in podcasts:
			subscribers = p[0]
			title = p[1]
			author = p[2]
			description = p[3]
			pID = p[4]
			results.append({"subscribers" : subscribers, "title" : title, "author" : author, "description" : description, "pid" : pID})
		close_conn(conn, cur)
		return results, 200

class Settings(Resource):
	@token_required
	def get(self):
		conn, cur = get_conn()
		data = jwt.decode(request.headers['token'], app.config['SECRET_KEY'])
		username = data['user']
		cur.execute("SELECT email FROM users WHERE username='%s'" % username)
		email = cur.fetchone()[0]
		close_conn(conn, cur)
		return {"email" : email}
		
	@token_required
	def put(self):
		data = jwt.decode(request.headers['token'], app.config['SECRET_KEY'])
		username = data['user']
		# args = request.get_json()
		conn, cur = get_conn()
		parser = reqparse.RequestParser(bundle_errors=True)
		parser.add_argument('oldpassword', type=str, required=True, help="Need old password", location="json")
		parser.add_argument('newpassword', type=str, location="json")
		parser.add_argument('newemail', type=str, location="json")
		args = parser.parse_args()
		# check current password
		cur.execute("SELECT hashedpassword FROM users WHERE username='%s'" % username)
		old_pw = cur.fetchone()[0].strip()
		if bcrypt.checkpw(args["oldpassword"].encode('UTF-8'), old_pw.encode('utf-8')):
			if args["newpassword"]:
				if args["oldpassword"] != args["newpassword"]:
					# change password
					password = args["newpassword"]
					password = password.encode('UTF-8')
					hashedpassword = bcrypt.hashpw(password, bcrypt.gensalt())
					cur.execute("UPDATE users SET hashedpassword='%s' WHERE username='%s' OR email = '%s'" % (hashedpassword.decode('UTF-8'), username, username))
			if args['newemail']:
				# change email
				cur.execute("UPDATE users SET email='%s' WHERE username='%s' OR email='%s'" % (args['newemail'], username, username))
			conn.commit()
			close_conn(conn, cur)
			return {"data" : "success"}, 200
		return {}, 400

	@token_required
	def delete(self):
		conn, cur = get_conn()
		user_id = get_user_id(cur)
		# delete from users
		cur.execute("DELETE FROM users WHERE id=%s" % user_id)
		# delete all subscriptions
		cur.execute("DELETE FROM subscriptions WHERE userId=%s" % user_id)
		# delete podcast account
		cur.execute("DELETE FROM podcastratings WHERE userId=%s" % user_id)
		# delete episode ratings
		cur.execute("DELETE FROM episoderatings WHERE userId=%s" % user_id)
		# delete listens
		cur.execute("DELETE FROM listens WHERE userId=%s" % user_id)
		# delete seach queries
		cur.execute("DELETE FROM searchqueries WHERE userId=%s" % user_id)
		# delete rejected recommendations
		cur.execute("DELETE FROM rejectedrecommendations WHERE userId=%s" % user_id)
		conn.commit()
		close_conn(conn,cur)
		return {"data" : "account deleted"}, 200


class Podcast(Resource):
	def get(self, id):
		conn, cur = get_conn()
		cur.execute("SELECT rssFeed FROM Podcasts WHERE id=(%s)", (id,))
		res = cur.fetchone()
		close_conn(conn,cur)
		if res:
			url = res[0]
			resp = requests.get(url)
			if resp.status_code == 200:
				return {"xml": resp.text}, 200
			else:
				return {}, 500 # 500 might not the right code
		else:
			return {}, 404

class Recommendations(Resource):
	def get(self):
		conn, cur = get_conn()



api.add_resource(Unprotected, "/unprotected")
api.add_resource(Protected, "/protected")
api.add_resource(Login, "/login")
api.add_resource(Users, "/users")
api.add_resource(Settings, "/users/self/settings")
api.add_resource(Podcasts, "/podcasts")
api.add_resource(Podcast, "/podcasts/<int:id>")


if __name__ == '__main__':
	app.run(debug=True)
