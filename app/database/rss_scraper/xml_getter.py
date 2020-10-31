import sys
import psycopg2
import socket
import xmltodict
import requests

categoryIds = {}

def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)

try:
    conn = psycopg2.connect(dbname="ultracast", user="brojogan", password="GbB8j6Op", host="polybius.bowdens.me", port=5432)
except Exception as e:
    eprint(e)
    exit(1)


count = 0
total = 0

cur = conn.cursor()
try:
    cur.execute("""
        select count(*) from podcasts
        where xml is null
        """)
    total = cur.fetchone()[0]
    cur.execute("""
            select id,rssfeed from podcasts
            where xml is null
        """)
except Exception as e:
    eprint(e)
    cur.close()
    conn.close()
    exit(1)

podcasts = cur.fetchall()
cur.close()

for podcast in podcasts:
    podcastid = podcast[0]
    url = podcast[1]
    eprint("{}: {}".format(podcastid,url))
    data = {}
    try:
        xml = requests.get(url)
        data = xml.text
        parsed = xmltodict.parse(xml.text)
    except Exception as e:
        eprint(" - error accessing:")
        eprint(e)
        print(url)
        cur = conn.cursor()
        cur.execute("update podcasts set badxml='t' where id=%s", (podcastid,))
        cur.close()
        continue

    try:
        cur = conn.cursor()
        cur.execute("""
            update podcasts set xml=%s, lastupdated=now(), badxml='f'
            where id=%s""",
            (data, podcastid))
        cur.close()
    except Exception as e:
        eprint(" - error adding to db")
        eprint(e)
        continue

    eprint("finished {}".format(url))
    conn.commit()
    count += 1
    eprint("line {}/{} finished\n".format(count, total))


conn.close()
