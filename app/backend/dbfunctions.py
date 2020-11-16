#from SemaThreadPool import SemaThreadPool
from main import conn_pool
# conn_pool = SemaThreadPool(1, 50,\
# 	 dbname="ultracast", user="brojogan", password="GbB8j6Op", host="polybius.bowdens.me", port=5432)

def get_conn():
	conn = conn_pool.getconn()
	cur = conn.cursor()
	return conn, cur

def close_conn(conn, cur):
	cur.close()
	conn_pool.putconn(conn)
