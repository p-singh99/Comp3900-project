from flask_restful import Resource
from functools import wraps
from flask_restful import Api, Resource, reqparse
import user_functions as uf
import dbfunctions as df

class Recommendations(Resource):
	@uf.token_required
	def get(self):
		conn, cur = df.get_conn()
		user_id = uf.get_user_id()
		recs = []
		cur.execute("select distinct * from recommendations(%s)", (user_id,))
		results = cur.fetchall()
		recs = [{"title": i[0], "thumbnail": i[1], "id": i[2], "subs": i[3], "eps": i[4], "rating": f"{i[5]:.1f}"} for i in results]
		df.close_conn(conn,cur)
		return {"recommendations" : recs}