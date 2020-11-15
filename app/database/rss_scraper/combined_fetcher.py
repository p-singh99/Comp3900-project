import sys
import psycopg2
import socket
import xmltodict
import requests

def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)

def extractItunesCategories(categories):
    if not isinstance(categories, list):
        categories = [categories]
    retl = []
    for c in categories:
        retl.extend(_extractItunesCategories("", c, "  "))
    return retl

def _extractItunesCategories(parent, node, foo):
    list = []
    for child in node:
        if child == "@text":
            list.append((node["@text"], parent))
            parent = node["@text"]
        else:
            list.extend(_extractItunesCategories(parent, node[child], foo+"  "))
    return list

def insertCategory(category, parentid, itunes):
    cur = conn.cursor()
    cur.execute("""
        insert into categories (name,parentCategory,itunes)
        values (%s,%s,%s)
        returning id
    """,
    (category, parentid,itunes))
    categoryid = cur.fetchone()[0]
    cur.close()
    return categoryid

def getCategory(category):
    cur = conn.cursor()
    cur.execute("""
        select id from categories
        where name = %s;
    """,
    (category,))
    res = cur.fetchone()
    cur.close()
    return None if res is None else res[0]


def getOrInsertCategory(c,itunes=True):
    category = c[0]
    parent = c[1]
    categoryid = None
    parentid = None
    if parent:
        parentid = getCategory(parent)
        if parentid is None:
            parentid = insertCategory(parent,None,itunes)
    # we should now have a parentid (or None if there is no parent)
    categoryid = getCategory(category)
    if categoryid is None:
        categoryid = insertCategory(category,parentid,itunes)
    if categoryid is None:
        raise Exception("failed to get categoryid from db/dict")
    return (categoryid, parentid)

def getOrInsertKeyword(k):
    category = (k,None)
    return getOrInsertCategory(category,itunes=False)[0]

def insertPodcastCategory(podcastid, categoryid):
    cur = conn.cursor()
    cur.execute("""
        insert into podcastCategories (podcastId, categoryId)
        values (%s, %s)
        """,
        (podcastid, categoryid)
    )
    eprint("  inserted podcast category with ({},{})".format(podcastid, categoryid))
    cur.close()



socket.setdefaulttimeout(10)

try:
    conn = psycopg2.connect(dbname="ultracast", user="brojogan", password="GbB8j6Op", host="polybius.bowdens.me", port=5432)
    #conn = psycopg2.connect(dbname="ultracast")
except Exception as e:
    eprint(e)
    exit(1)


count = 0

for line in sys.stdin:
    url = line.strip()
    data = {}
    categories = []
    keywords = []
    podcastid = -1
    try:
        xml = requests.get(url)
        data = xmltodict.parse(xml.text)
        channel = data["rss"]["channel"]
        eprint(channel["title"])
        title = channel["title"]
        author = channel.get("author")
        if channel.get("itunes:author"):
            author = channel.get("itunes:author")
        description = channel.get("description")
        thumbnail = channel["image"].get("url") if channel.get("image") else None

    except Exception as e:
        eprint(" - error parsing:")
        eprint(e)
        print(url)
        continue

    eprint("    inserting podcast with details:")
    eprint("    title: {}".format(title))
    eprint("    author: {}".format(author))
    eprint("    description: {}".format(author[0:min([len(author), 20])] if author else None))
    eprint("    thumbnail: {}".format(thumbnail))

    try:
        cur = conn.cursor()
        cur.execute("""
            insert into podcasts
            (rssfeed, title, author, description, thumbnail, xml, lastupdated, badxml)
            values (%s, %s, %s, %s, %s, %s, now() at time zone 'utc', 'f')
            returning id
        """, (url, title, author, description, thumbnail, xml.text))
        podcastid = cur.fetchone()[0]
        conn.commit()
        cur.close()
    except Exception as e:
        eprint(" - error adding podcast")
        eprint(e)
        conn.rollback()
        continue

    try:
        if channel.get("itunes:category"):
            categories = extractItunesCategories(channel["itunes:category"])
        if channel.get("keywords"):
            if isinstance(channel.get("keywords"), str):
                # sanity check there's only 1 instance of keywords
                keywords.extend(channel.get("keywords").split(","))
        if channel.get("itunes:keywords"):
            if isinstance(channel.get("itunes:keywords"), str):
                # sanity check there's only 1 instance of itunes:keywords
                keywords.extend(channel.get("itunes:keywords").split(","))
        if channel.get("category"):
            if isinstance(channel.get("category"), list):
                keywords.extend(channel.get("category"))
            elif isinstance(channel.get("category"), str):
                keywords.append(channel.get("category"))
            else:
                eprint("  not sure what {} is. not a list or string".format(channel.get("category")))
    except Exception as e:
        eprint(" - error getting categories:")
        eprint(e)
        continue

    try:
        categories = list(set([(x[0].lower().strip(), x[1].lower().strip()) for x in categories if x]))
        keywords = list(set([x.lower().strip() for x in keywords if x]))
        keywords = [x for x in keywords if x not in [y[0] for y in categories if y]] # filter out double ups in keywords
        eprint(" - categories are: {}".format(categories))
        eprint(" - keywords are: {}".format(keywords))
    except Exception as e:
        eprint(" - error boiling down categories and keywords")
        eprint(e)
        continue


    for category in categories:
        try:
            categoryid, parentid = getOrInsertCategory(category)
        except Exception as e:
            eprint("  error in getOrInsertCategory")
            eprint(e)
            conn.rollback()
            continue

        # insert podcastCategories
        try:
            eprint("  inserting podcastCategory ({},{})".format(podcastid, categoryid))
            insertPodcastCategory(podcastid, categoryid)
        except Exception as e:
            eprint(" -- error inserting podcast category ({}, {})".format(podcastid, categoryid))
            eprint(e)
            conn.rollback()
            continue

    for keyword in keywords:
        try:
            categoryid = getOrInsertKeyword(keyword)
        except Exception as e:
            eprint("       error in getOrInsertKeyword")
            eprint(e)
            conn.rollback()
            continue
        # insert podcastCategories
        try:
            eprint("  inserting podcastCategory ({},{})".format(podcastid, categoryid))
            insertPodcastCategory(podcastid, categoryid)
        except Exception as e:
            eprint(" -- error inserting podcast category ({}, {})".format(podcastid, categoryid))
            eprint(e)
            conn.rollback()
            continue

    eprint("finished {}".format(url))
    conn.commit()
    count += 1
    eprint("line {} finished\n".format(count))


conn.close()
