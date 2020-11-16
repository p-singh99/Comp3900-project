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