from main import conn_pool as pool
import requests
import time

conn = pool.getconn()
cur = conn.cursor()
cur.execute("select id from podcasts where id not in (select distinct podcastId from episodes)")
podcastIds = [x[0] for x in cur.fetchall()]
total = len(podcastIds)
pool.putconn(conn)

for i, podcastId in enumerate(podcastIds):
    r = requests.get("http://localhost:5000/podcasts/{}".format(podcastId))
    print("{}/{}: {}".format(i, total, podcastId))
    time.sleep(1/3)
