from flask_restful import Resource
from user_functions import token_required

class Protected(Resource):
	@token_required
	def get(self):
		return {'message': 'not anyone'}, 200