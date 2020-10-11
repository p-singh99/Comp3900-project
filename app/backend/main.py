from flask import Flask, jsonify, request, make_response
from flask_restful import Api, Resource
import psycopg2
import jwt
import bcrypt
import datetime
from functools import wraps


app = Flask(__name__)
api = Api(app) 

#CHANGE SECRET KEY
app.config['SECRET_KEY'] = 'secret_key'

def create_token(username):
	return jwt.encode({'user' : username, 'exp' : datetime.datetime.utcnow() + datetime.timedelta(minutes=20)}, app.config['SECRET_KEY'])

def get_db():
	# conn = psycopg2.connect(host="localhost", database="pod", user="postgres", password="m")
	conn = psycopg2.connect(dbname="ultracast", user="brojogan", password="GbB8j6Op", host="polybius.bowdens.me", port=5432)
	cur = conn.cursor()
	return conn, cur


def token_required(f):
	@wraps(f)
	def decorated(*args, **kwargs):
		token = request.args.get('token')
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
		conn, cur = get_db()
		#Check if username exists
		cur.execute("SELECT count(*) FROM users WHERE username='%s'" % username)
		if cur.fetchone() is None:
			cur.close()
			conn.close()
			return {"data" : "Login Failed"}, 401
		cur.execute("SELECT hashedpassword FROM users WHERE username='%s'" % username)
		pw = cur.fetchone()[0].strip()
		pw = pw.encode('UTF-8')
		cur.close()
		conn.close()
		# pw = pw.encode('UTF-8')
		password = request.form.get('password')
		hashed = bcrypt.hashpw(b"name", bcrypt.gensalt())
		# print(hashed)
		if bcrypt.checkpw(password.encode('UTF-8'), pw):
			return create_token(username), 200
		return {"data" : "Login Failed"}, 401
		


		

class Users(Resource):
	#signup
	def post(self):
		conn, cur = get_db()
		user = request.form.get('username')
		email = request.form.get('email')
		passw = request.form.get('password')
		pw = passw.encode('UTF-8')
		hashed = bcrypt.hashpw(pw, bcrypt.gensalt())
		# cur = conn.cursor()
		exists = False
		errors = []
		data = request.headers['token']
		# check if username exists in database
		cur.execute("SELECT * FROM users WHERE username='%s'" % user)
		if cur.fetchone():
			error = True;
			error_msg.append({"error" : "Username already exists"})
		# check if email exists in database
		cur.execute("SELECT * FROM users WHERE username='%s'" % email)
		if cur.fetchone():
			error = True;
			error_msg.append({"error" : "Email already exists"})
		if error:
			cur.close()
			conn.close()
			return error_msg, 409
		# get next unique id number
		cur.execute("select count(*) from users");
		count = cur.fetchone()[0] + 1
		# create entry for username/email/pass
		cur.execute("insert into users (id, username, email, hashedpassword) values ('%s',%s, %s, %s)", (count, user, email, hashed.decode("UTF-8")))
		conn.commit()
		cur.close()
		conn.close()
		# return token	
		return get_token(user), 201	


	@token_required
	def delete(self):
		if not request.headers.get('token'):
			return {"error" : "FAILED"}, 401
		token = request.headers['token']
		data = jwt.decode(token, app.config['SECRET_KEY'])
		sql = "DELETE FROM users WHERE username='%s';" % data['user']
		conn, cur = get_db()
		cur.execute(sql)
		conn.commit()
		cur.close()
		conn.close()
		return {"data": "Account Deleted"}, 200


api.add_resource(Unprotected, "/unprotected")
api.add_resource(Protected, "/protected")
api.add_resource(Login, "/login")
api.add_resource(Users, "/users")


if __name__ == '__main__':
	app.run(debug=True)
