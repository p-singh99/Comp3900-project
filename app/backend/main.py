from flask import Flask, jsonify, request, make_response
from flask_restful import Api, Resource
from flask_cors import CORS, cross_origin
import psycopg2
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
conn = psycopg2.connect(dbname="ultracast", user="brojogan", password="GbB8j6Op", host="polybius.bowdens.me", port=5432)

def create_token(username):
	token = jwt.encode({'user' : username, 'exp' : datetime.datetime.utcnow() + datetime.timedelta(minutes=20)}, app.config['SECRET_KEY'])
	return token.decode('UTF-8')

# def get_db():
# 	# conn = psycopg2.connect(host="localhost", database="pod", user="postgres", password="m")
# 	cur = conn.cursor()
# 	return conn, cur


def token_required(f):
	@wraps(f)
	def decorated(*args, **kwargs):
		token = request.headers.get('token')
		if not token:
			return {'message' : 'token is missing'}, 401
		try:
			data = jwt.decode(token, app.config['SECRET_KEY'])
		except:
			return {'message' : 'token is invalid'}, 401
		return f(*args, **kwargs)
	return decorated


class Unprotected(Resource):
	def get(self):
		return {'message': 'anyone'}, 200

class Protected(Resource):
	@token_required
	def get(self):
		return {'message': 'not anyone'}, 200

class Login(Resource):
	def post(self):
		username = request.form.get('username')
		password = request.form.get('password')
		# Check if username or email
		cur = conn.cursor()
		# Check if username exists
		# cur.execute("SELECT password FROM users WHERE username='%s'" % username)
		cur.execute("SELECT username, hashedpassword FROM users WHERE username='%s' OR email='%s'" % (username, username))
		res = cur.fetchone()
		if res:
			username = res[0].strip()
			pw = res[1].strip()
			pw = pw.encode('UTF-8')
			cur.close()
			password = request.form.get('password')
			hashed = bcrypt.hashpw(b"name", bcrypt.gensalt())
			if bcrypt.checkpw(password.encode('UTF-8'), pw):
				return {'token' : create_token(username), 'user': username}, 200
		return {"data" : "Login Failed"}, 401
				

class Users(Resource):
	#signup
	def post(self):
		cur = conn.cursor()
		username = request.form.get('username').lower()
		email = request.form.get('email').lower()
		passw = request.form.get('password')
		pw = passw.encode('UTF-8')
		hashed = bcrypt.hashpw(pw, bcrypt.gensalt())
		error = False
		error_msg = []
		# data = request.headers['token']
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
		# return token	
		return {'token' : create_token(username), 'user': username}, 201

	@token_required
	def delete(self):
		if not request.headers.get('token'):
			return {"error" : "FAILED"}, 401
		token = request.headers['token']
		data = jwt.decode(token, app.config['SECRET_KEY'])
		sql = "DELETE FROM users WHERE username='%s';" % data['user']
		cur = conn.cursor()
		cur.execute(sql)
		conn.commit()
		cur.close()
		return {"data": "Account Deleted"}, 200
	

class Podcasts(Resource):
	def get(self):
		search = request.args.get('search_query')
		if search is None:
			return {"data": "Bad Request"}, 400
		# search = request.form.get('search-input')
		cur = conn.cursor()
		cur.execute("""SELECT count(s.userid), p.title, p.author, p.description
             			FROM   Subscriptions s
             				FULL OUTER JOIN Podcasts p
                		ON s.podcastId = p.id
             			WHERE  to_tsvector(p.title || ' ' || p.author || ' ' || p.description) @@ plainto_tsquery('%s')
             			GROUP BY p.id;""" % search
           		   )

		podcasts = cur.fetchall()
		cur.close()
		results = []
		for p in podcasts:		
			subscribers = p[0]
			title = p[1]
			author = p[2]
			description = p[3]
			results.append({"subscribers" : subscribers, "title" : title, "author" : author, "description" : description})
		return results, 200

class Delete(Resource):
	#@token_required
	def delete(self):
		if not request.headers.get('token'):
			return {"error" : "FAILED"}, 401
		token = request.headers['token']
		data = jwt.decode(token, app.config['SECRET_KEY'])
		sql = "DELETE FROM users WHERE username='%s';" % data['user']
		cur = conn.cursor()
		cur.execute(sql)
		conn.commit()
		cur.close()
		return {"data": "Account Deleted"}, 200

class Settings(Resource):

	def post(self, name):
		return {"data": f"{name}"}

	def put(self, name):
		if name == "password":
			# change password
			return {"data" : f"{name}"}

		elif name == "email":
			# change email
			return {"data" : f"{name}"}

		return {"data" : "Failed"}

class Podcast(Resource):
	def get(self, id):
		cur = conn.cursor()
		cur.execute("SELECT rssFeed FROM Podcasts WHERE id=(%s)", (id,))
		res = cur.fetchone()
		cur.close()
		if res:
			url = res[0]
			resp = requests.get(url)
			if resp.status_code == 200:
				return {"xml": resp.text}, 200
			else:
				return {}, 500 # 500 might not the right code
		else:
			return {}, 404

api.add_resource(Unprotected, "/unprotected")
api.add_resource(Protected, "/protected")
api.add_resource(Login, "/login")
api.add_resource(Users, "/users")
api.add_resource(Delete, "/users/self")
api.add_resource(Settings, "/users/self/<string:name>")
api.add_resource(Podcasts, "/podcasts")
api.add_resource(Podcast, "/podcasts/<int:id>")


if __name__ == '__main__':
	app.run(debug=True)
