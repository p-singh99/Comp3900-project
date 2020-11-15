import feedparser
import sys
import psycopg2
import socket

def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)

test=False
socket.setdefaulttimeout(10)

try:
    conn = psycopg2.connect(dbname="ultracast", user="brojogan", password="GbB8j6Op", host="polybius.bowdens.me", port=5432)
except Exception as e:
    eprint(e)
    exit(1)

cur = conn.cursor()

count = 0

for line in sys.stdin:
    url = line.rstrip()
    eprint(url)
    data = {}
    try:
        data = feedparser.parse(url)
    except Exception as e:
        eprint(" - error parsing:")
        eprint(e)
        print(url)
        continue
    if data["bozo"]:
        eprint(" - malformed rss, continuing")
        print(url)
        continue
    try:
        cur.execute("""
            insert into podcasts
            (rssfeed, title, author, description, thumbnail)
            values (%s, %s, %s, %s, %s)
            returning id;
        """,
        (
            url,
            data.feed.get("title"),
            data.feed.get("author"),
            data.feed.get("description"),
            data.feed.get("image")["href"] if data.feed.get("image") else None
        ))
    except Exception as e:
        conn.rollback()
        eprint(" - error inserting into podcasts:")
        eprint(e)
        print(url)
        continue
    podcastid = cur.fetchone()[0]
    eprint("  inserted podcast with id {}".format(podcastid))

    categories = [data.feed.get("category")] if data.feed.get("category") else []
    #categories = [x.term for x in data.feed.get("tags",[]) if x.scheme == 'http://www.itunes.com/dtds/podcast-1.0.dtd']
    eprint(" - categories are: {}".format(categories))

    for category in categories:
        eprint("    - category: {}".format(category))
        try:
            cur.execute("""
                select id from categories
                where name = %s;
            """,
            (category,)
            )
        except Exception as e:
            eprint(" -- error getting category {}".format(category))
            eprint(e)
            continue
        categoryid = None
        res = cur.fetchone()
        if res is None:
            # we need to insert a new category
            try:
                cur.execute("""
                    insert into categories (name)
                    values (%s)
                    returning id
                    """,
                    (category,)
                )
            except Exception as e:
                conn.rollback()
                eprint(" -- error inserting new category {}".format(category))
                eprint(e)
                continue
            categoryid = cur.fetchone()[0]
            eprint("  inserted category '{}' with id {}".format(category ,categoryid))
        else:
            categoryid = res[0]
            eprint("  got category '{}' with id {}".format(category ,categoryid))

        # insert podcastCategories
        try:
            cur.execute("""
                insert into podcastCategories (podcastId, categoryId)
                values (%s, %s)
                """,
                (podcastid, categoryid)
            )
            eprint("  inserted podcast category with ({},{})".format(podcastid, categoryid))
        except Exception as e:
            eprint(" -- error inserting podcast category ({}, {})".format(podcastid, categoryid))
            eprint(e)
            continue
    eprint("finished {}".format(url))
    if test:
        conn.rollback()
        eprint("rolled back because in test mode")
    else:
        conn.commit()
        eprint("committed")
    count += 1
    eprint("line {} finished\n".format(count))


cur.close()
conn.close()
