import psycopg2
#other imports

###
# The following is a search on the podcasts. The part that is searched is in function plainto_tsquery() on line 17
# Currently if you search for a podcast with no subscribers it will not show up. not sure how to make the connection with 0 subs
# I've placed a search that doesn't account for subscribers below the line 27
###
conn = psycopg2.connect(dbname="ultracast", user="brojogan", password="GbB8j6Op", host="polybius.bowdens.me", port=5432)

#grabbing search inputs from UI

cur = conn.cursor()

cur.execute("SELECT count(*), podcasts.title, podcasts.author, podcasts.description
             FROM   Podcasts, Subscriptions
             WHERE  to_tsvector(podcasts.title || ' ' || podcasts.author || ' ' || podcasts.description) @@ plainto_tsquery('Chapo')
             AND (Subscriptions.podcastId = Podcasts.id) GROUP BY podcasts.id;"
           );
           
#   Subscriber Count | Podcast Title | Podcast Author | Podcast Description

print(cur.fetchall())

cur.close()
conn.close()

# SELECT count(*), podcasts.title, podcasts.author, podcasts.description
# FROM   Podcasts, Subscriptions
# WHERE  to_tsvector(podcasts.title || ' ' || podcasts.author || ' ' || podcasts.description) @@ plainto_tsquery('Chapo');
