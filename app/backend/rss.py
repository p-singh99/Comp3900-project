import datetime
import xmltodict
import socket
import requests
from psycopg2.extras import execute_values

# the number of seconds it takes for an rssfeed to go stale
TIME_TO_STALE = datetime.timedelta(minutes=10)
# spend no more than 10 seconds trying to fetch an rss feed
socket.setdefaulttimeout(10)

def fetch_xml(url):
    try:
        req = requests.get(url)
        xml = req.text
        return xml
    except Exception as e:
        return None



# code to fetch an rss feed and read it into the database
# first checks if the rss feed is stale yet
def update_rss(url, pool):
    conn = pool.getconn()
    cur = conn.cursor()
    cur.execute("""
        select id, lastUpdated, now() from podcasts
        where rssfeed=%s
        """, (url))
    res = cur.fetchone()
    cur.close()
    pool.putconn(conn)
    xml = None
    rss = None
    if res is None or len(res) == 0:
        # there's nothing from the db with the url specified
        return False, "podcast does not exist"
    else:
        podcastId = res[0]
        lastUpdated = res[1]
        now = res[2]
        if lastUpdated + TIME_TO_STALE > now:
            xml = fetch_xml(url)
            if xml is None:
                # we tried to get the xml but it didn't load
                # set in db
                try:
                    conn = pool.getconn()
                    cur = conn.cursor()
                    cur.execute("""
                        update podcasts set
                        badxml='t',
                        lastUpdated=now()
                        where id=%s
                    """, (podcastId,))
                    cur.close()
                    pool.putconn(conn)
                    return False, "could not fetch xml for existing podcast"
                except Exception as e:
                    print("Error accessing db")
                    print(e)
                    cur.close()
                    pool.putconn(conn)
                    return False, "db access error"
        else:
            # not enough time has passed to update the podcast
            return False, "entry not stale"
    # we now either have xml data or it is None
    if xml is None:
        except Exception("xml should never be none here")
    try:
        rss = xmltodict.parse(xml)
    except Exception as e:
        conn = pool.getconn()
        cur = conn.cursor()
        cur.execute("""
            update podcasts set
            badxml='t',
            xml=%s,
            lastUpdated=now()
            where id=%s
        """, (podcastId, xml))
        cur.close()
        pool.putconn(conn)
        return False, "invalid xml"
    
    # we now have the rss feed
    channel = rss["rss"]["channel"]
    rawEpisodes = channel.get("item")
    if not isinstance(episodes,list):
        rawEpisodes = [rawEpisodes]
    try:
        episodes = [(x["title"], x["guid"], 'now()') for x in rawEpisodes]
    except Exception as e:
        return False, "title or guid missing from one or more episodes"
    conn = pool.getconn()
    cur = conn.cursor()
    execute_values(cur, """
    insert into episodes (title, guid, created)
    values %s
    on conflict do nothing
    """, episodes)

    # now that the episodes are inserted, we must add the notifications
    cur.execute("""
    select userId from subscriptions
    where podcastId=%s
    """, (podcastId,))
    subscribers = cur.fetchall()
    if subscribers is None or len(subscribers) == 0:
        return True, "no subscribers"
    notifications = []
    for s in subscribers:
        notifications.extend([
            podcastId, x[1], s[0]
        ] for x in episodes)

    

    

        



   
    

