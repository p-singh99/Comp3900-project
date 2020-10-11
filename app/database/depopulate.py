import psycopg2
import threading
import sys

running=False

def confirm(result):
    s = input("This will wipe the database. Are you sure you want to do this? y/n ")
    result["running"] = (s=="y")   

results = dict()
t = threading.Thread(target=confirm, args=(results,))
t.start()

conn = psycopg2.connect(dbname="ultracast", user="brojogan", password="GbB8j6Op", host="polybius.bowdens.me", port=5432)
cur = conn.cursor()

t.join()

if (results["running"]):
    print("deleting from all tables...")
    cur.execute("delete from subscriptions")
    cur.execute("delete from episodes")
    cur.execute("delete from podcastCategories")
    cur.execute("delete from categories");
    cur.execute("delete from podcasts");
    cur.execute("delete from users");

    conn.commit()
    print("operation complete")
else:
    print("operation cancelled")

cur.close()
conn.close()

