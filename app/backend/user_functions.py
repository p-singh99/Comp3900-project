from flask import request
import jwt
import datetime
from functools import wraps
from main import app

def create_token(user_id):
	token = jwt.encode({'user' : user_id, 'exp' : datetime.datetime.utcnow() + datetime.timedelta(hours=24)}, app.config['SECRET_KEY'])
	return token.decode('UTF-8')

def token_required(f):
	@wraps(f)
	def decorated(*args, **kwargs):
		token = request.headers.get('token')
		if not token:
			return {'error' : 'token is missing'}, 401
		try:
			# fails if token format is invalid or timstamp expired
			data = jwt.decode(token, app.config['SECRET_KEY'])
		except:
			return {'error' : 'token is invalid'}, 401
		return f(*args, **kwargs)
	return decorated

def get_user_id():
	token = request.headers.get('token')
	if token:
		try:
			data = jwt.decode(token, app.config['SECRET_KEY'])
			#cur.execute("SELECT id FROM users WHERE username =%s or email = %s", (data['user'], data['user']))
		except:
			return None
		return data['user']
	return None
