import feedparser
import sys
import psycopg2
import socket

test=False
socket.setdefaulttimeout(10)

try:
    conn = psycopg2.connect(dbname="ultracast", user="brojogan", password="GbB8j6Op", host="polybius.bowdens.me", port=5432)
except Exception as e:
    print(e)
    exit(1)

cur = conn.cursor()

count = 0

for line in sys.stdin:
    url = line.rstrip()
    print(url)
    data = {}
    try:
        data = feedparser.parse(url)
    except Exception as e:
        print(" - error parsing:")
        print(e)
        continue
    if data["bozo"]:
        print(" - malformed rss, continuing")
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
        print(" - error inserting into podcasts:")
        print(e)
        continue
    podcastid = cur.fetchone()[0]
    print("  inserted podcast with id {}".format(podcastid))

    categories = [data.feed.get("category")] if data.feed.get("category") else []
    #categories = [x.term for x in data.feed.get("tags",[]) if x.scheme == 'http://www.itunes.com/dtds/podcast-1.0.dtd']
    print(" - categories are: {}".format(categories))

    for category in categories:
        print("    - category: {}".format(category))
        try:
            cur.execute("""
                select id from categories
                where name = %s;
            """,
            (category,)
            )
        except Exception as e:
            print(" -- error getting category {}".format(category))
            print(e)
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
                print(" -- error inserting new category {}".format(category))
                print(e)
                continue
            categoryid = cur.fetchone()[0]
            print("  inserted category '{}' with id {}".format(category ,categoryid))
        else:
            categoryid = res[0]
            print("  got category '{}' with id {}".format(category ,categoryid))

        # insert podcastCategories
        try:
            cur.execute("""
                insert into podcastCategories (podcastId, categoryId)
                values (%s, %s)
                """,
                (podcastid, categoryid)
            )
            print("  inserted podcast category with ({},{})".format(podcastid, categoryid))
        except Exception as e:
            print(" -- error inserting podcast category ({}, {})".format(podcastid, categoryid))
            print(e)
            continue
    print("finished {}".format(url))
    if test:
        conn.rollback()
        print("rolled back because in test mode")
    else:
        conn.commit()
        print("committed")
    count += 1
    print("line {} finished\n".format(count))


cur.close()
conn.close()
