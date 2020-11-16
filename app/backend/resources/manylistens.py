from flask_restful import Resource
from functools import wraps
from flask_restful import Api, Resource, reqparse
import user_functions as uf
import dbfunctions as df

class ManyListens(Resource):
	@uf.token_required
	def get(self, podcastId):
		conn, cur = df.get_conn()
		user_id = uf.get_user_id()
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
		return jsonready, 200