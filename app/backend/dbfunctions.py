from SemaThreadPool import SemaThreadPool
import os

conn_pool = None
if os.environ.get("BROJOGAN_USE_LOCAL") == "1":
    conn_pool = SemaThreadPool(1,50,dbname="ultracast")
else:
    conn_pool = SemaThreadPool(1, 50,\
             dbname="ultracast", user="brojogan", password="GbB8j6Op", host="polybius.bowdens.me", port=5432)

def get_conn():
	conn = conn_pool.getconn()
	cur = conn.cursor()
	return conn, cur

def close_conn(conn, cur):
	cur.close()
	conn_pool.putconn(conn)
