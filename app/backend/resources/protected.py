from flask_restful import Resource
from backend import main

class Protected(Resource):
	@main.token_required
	def get(self):
		return {'message': 'not anyone'}, 200