from flask import Flask, jsonify, request, make_response
from flask_restful import Api, Resource, reqparse
from flask_cors import CORS, cross_origin

app = Flask(__name__)
api = Api(app)
CORS(app)


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

def get_user_id(cur):
	token = request.headers.get('token')
	if token:
		try:
			data = jwt.decode(token, app.config['SECRET_KEY'])
			#cur.execute("SELECT id FROM users WHERE username =%s or email = %s", (data['user'], data['user']))
		except:
			return None
		return data['user']
	return None

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
api.add_resource(Notification, "/users/self/notification/<int:notificationId>")
api.add_resource(Listens, "/users/self/podcasts/<int:podcastId>/episodes/time")
api.add_resource(ManyListens, "/users/self/podcasts/<int:podcastId>/time")
api.add_resource(Ratings, "/users/self/ratings/<int:id>")