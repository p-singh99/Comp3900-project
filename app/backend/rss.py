import datetime
import xmltodict
import socket
import requests
from psycopg2.extras import execute_values
from threading import BoundedSemaphore, Lock


# spend no more than 10 seconds trying to fetch an rss feed
socket.setdefaulttimeout(10)

sem = BoundedSemaphore(value=5)
# using a dict of locks we can have only 1 thread 
# updating each podcast at a time, so future podcasts
# will fail
dictLock = Lock()
urlLocks = {}

def fetch_xml(url):
    try:
        req = requests.get(url)
        xml = req.text
        return xml
    except Exception as e:
        return None


def update_rss(url, pool):
    # grab the dict lock, then check to see if a lock
    # for the url exists. if it does, acquire it
    # then release the dict lock
    # Do this before entering the semaphore so
    # that waiting on the dict lock/url lock 
    # wont waste space in the semaphore
    dictLock.acquire()
    if urlLocks.get(url):
        urlLocks[url].acquire()
    else:
        urlLocks[url] = Lock()
        urlLocks[url].acquire()
    dictLock.release()

    sem.acquire()
    print("sem's value is {}".format(sem._value))
    try:
        print("entering update rss for {}".format(url))
        
        updated, msg = _update_rss(url,pool)
        print("exiting update rss {} with. {} update: {}".format(url, "did" if updated else "did not", msg))
    except Exception as e:
        print("an uncaught error occured in _update_rss: for {}".format(url))
        print(e)
    finally:
        sem.release()
        urlLocks[url].release()


# code to fetch an rss feed and read it into the database
# first checks if the rss feed is stale yet
def _update_rss(url, pool):
    conn = pool.getconn()
    cur = conn.cursor()
    cur.execute("""
        select id, lastUpdated, now() at time zone 'utc' from podcasts
        where rssfeed=%s
        """, (url,))
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
        if lastUpdated is None:
            lastUpdated = datetime.datetime(year=1970, month=1, day=1)
        now = res[2]
        TIME_TO_STALE = datetime.timedelta(minutes=10)

        print("now is {}, lastUpdated is {}, stale is {}".format(now, lastUpdated, lastUpdated + TIME_TO_STALE))
        if (lastUpdated + TIME_TO_STALE) < now:
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
                        lastUpdated=now() at time zone 'utc'
                        where id=%s
                    """, (podcastId,))
                    conn.commit()
                    cur.close()
                    pool.putconn(conn)
                    return False, "could not fetch xml for existing podcast"
                except Exception as e:
                    print("Error accessing db")
                    print(e)
                    return False, "db access error"
        else:
            # not enough time has passed to update the podcast
            return False, "entry not stale"
    # we now either have xml data or it is None
    if xml is None:
        raise Exception("xml should never be none here")
    try:
        rss = xmltodict.parse(xml)
    except Exception as e:
        conn = pool.getconn()
        cur = conn.cursor()
        cur.execute("""
            update podcasts set
            badxml='t',
            xml=%s,
            lastUpdated=now() at time zone 'utc'
            where id=%s
        """, (xml, podcastId))
        conn.commit()
        cur.close()
        pool.putconn(conn)
        return False, "invalid xml"

    channel = None
    # we now have the rss feed
    try:
        channel = rss["rss"]["channel"]
    except Exception as e:
        conn = pool.getconn()
        cur = conn.cursor()
        cur.execute("""
            update podcasts set
            badxml='t',
            xml=%s,
            lastUpdated=now() at time zone 'utc'
            where id=%s
        """, (xml, podcastId))
        conn.commit()
        cur.close()
        pool.putconn(conn)
        return False, "channel node missing from xml"
    
    # set the new xml in the podcast table
    conn = pool.getconn()
    cur = conn.cursor()
    cur.execute("""
        update podcasts set
        badxml='f',
        xml=%s,
        lastUpdated=now() at time zone 'utc'
        where id=%s
    """, (xml, podcastId))

    cur.execute("""
        select guid from episodes
        where podcastId=%s
    """, (podcastId,))
    res = cur.fetchall()
    existingEpisodes = []
    if res:
        existingEpisodes = [x[0] for x in res]

    conn.commit()
    cur.close()
    pool.putconn(conn)

    rawEpisodes = channel.get("item")
    episodes = []
    if not isinstance(rawEpisodes,list):
        rawEpisodes = [rawEpisodes]
    try:
        for x in rawEpisodes:
            title = x["title"] if isinstance(x["title"], str) else x["title"]["#text"]
            guid = x["guid"] if isinstance(x["guid"], str) else x["guid"]["#text"]
            description = x.get("description")
            duration = x.get("itunes:duration")
            pubdate = x.get("pubDate")
            if guid not in existingEpisodes:
                episodes.append((podcastId, title, guid, description, duration, pubdate, str(datetime.datetime.utcnow())))
    except Exception as e:
        return False, "title or guid missing from one or more episodes: {}".format(str(e))
    conn = pool.getconn()
    cur = conn.cursor()
    execute_values(cur, """
    insert into episodes (podcastid, title, guid, description, duration, pubdate, created)
    values %s
    on conflict (podcastId, guid) do nothing
    """, episodes)
    #cur.execute("""
    #update episodes set created=now() at time zone 'utc'
    #where podcastid=%s and created is null
    #""", (podcastId,))
    conn.commit()

    # now that the episodes are inserted, we must add the notifications
    cur.execute("""
    select userId from subscriptions
    where podcastId=%s
    """, (podcastId,))
    subscribers = cur.fetchall()
    if subscribers is None or len(subscribers) == 0:
        cur.close()
        pool.putconn(conn)
        return True, "no subscribers"
    notifications = []
    for s in subscribers:
        for x in episodes:
            notifications.append(
                (podcastId, x[2], s[0], 'unread')
            )

    execute_values(cur,"""
    insert into notifications (podcastid, episodeguid, userid, status)
    values %s
    on conflict (podcastid, episodeguid, userid) do nothing
    """, notifications)
    conn.commit()
    cur.close()
    pool.putconn(conn)
    return True, "inserted episodes and notifications"

    

    

        



   
    

