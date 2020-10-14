import psycopg2
import sys

print("establishing connection... ", end='', flush=True)
conn = psycopg2.connect(dbname="ultracast", user="brojogan", password="GbB8j6Op", host="polybius.bowdens.me", port=5432)
cur = conn.cursor()


print("established.")
print("Checking database is empty... ",end='', flush=True)
cur.execute("select count(*) from users");
print("checked")
count = cur.fetchone()[0]
if (count != 0):
    print("Looks like the database is not empty (users had at least 1 record in it). Try depopulating it first")
    sys.exit("operation cancelled")
else:
    print("Database looks empty (Users had no records in it). Continuing")



print("Inserting users... ", end='', flush=True)

cur.execute("""insert into users values
            (default, 'tom', 'tom@example.com', '$2b$12$vo5q.Bpwl5myC3qTww44EOrqYVE1qZTCM1oJIhhFb6Vq8X0U2KTCm'),
            (default, 'pawanjot', 'pawanjot@example.com', '$2b$12$mEXlUC8n0wJH8blt26KeVujn4aga3NJX7RV4M9Vx3yrPJu3YlV8rW'),
            (default, 'justin', 'justing@example.com', '$2b$12$b0QdZw3lLRjUI3nTKnmNyu5OUTvmjZb1eIvo9hdVbzY1G8Nxgx75y'),
            (default, 'nich', 'nich@example.com', '$2b$12$SfoSQ3Pq1vt24QKHtsCIWONJ39C9W1/yWJWclAA8Y43aMldi1q1Jq'),
            (default, 'michael', 'mc@example.com', '$2b$12$HGJribFoHIx53aCxqkr1I.efHZfYfpx44zk59huIWQ.mfWMh/z75K');
        """)
print("inserted.\nInserting podcasts... ", end='', flush=True)
cur.execute("""insert into podcasts values
            (default, 'http://www.hellointernet.fm/podcast?format=rss', 'Hello Internet', 'CGP Grey and Brady Haran', 'Presented by CGP Grey and Dr. Brady Haran.', 'https://images.squarespace-cdn.com/content/52d66949e4b0a8cec3bcdd46/1391195775824-JVU9K0BX50LWOKG99BL5/Hello+Internet.003.png?content-type=image%2Fpng'),
            (default, 'http://feeds.feedburner.com/dancarlin/history', 'Hardcore History', 'Dan Carlin', 'In "Hardcore History" journalist and broadcaster Dan Carlin takes his "Martian", unorthodox way of thinking and applies it to the past. Was Alexander the Great as bad a person as Adolf Hitler? What would Apaches with modern weapons be like? Will our modern civilization ever fall like civilizations from past eras? This isn''t academic history (and Carlin isn''t a historian) but the podcast''s unique blend of high drama, masterful narration and Twilight Zone-style twists has entertained millions of listeners.', 'http://www.dancarlin.com/graphics/DC_HH_iTunes.jpg'),
            (default, 'http://feeds.soundcloud.com/users/soundcloud:users:211911700/sounds.rss', 'Chapo Trap House', 'Chapo Trap House', 'Podcast by Chapo Trap House', 'http://i1.sndcdn.com/avatars-000230770726-ib4tc4-original.jpg'),
            (default, 'http://feeds.99percentinvisible.org/99percentinvisible', '99% Invisible', 'Roman Mars', '<![CDATA[<p>We''re excited to celebrate the release of <strong><em><a href="https://99percentinvisible.org/book/" rel="nofollow" target="_blank">The 99% Invisible City</a></em></strong> book by host Roman Mars and producer Kurt Kohlstedt with a guided audio tour of beautiful downtown Oakland, California.</p>

            <p>In this episode, we explain how anchor plates help hold up brick walls; why metal fire escapes are mostly found on older buildings; what impact camouflaging defensive designs has on public spaces; who benefits from those spray-painted markings on city streets, and much more.</p>

            <p>Plus, At the end of the tour, stick around for a behind the scenes look at the book as we answer a series of fan-submitted questions about how it was created, offering a window into the writing, illustration and design processes.</p>

            <p><a href="https://99percentinvisible.org/?p=34212&amp;post_type=episode" rel="nofollow" target="_blank">Exploring The 99% Invisible City</a></p>]]>', 'https://f.prxu.org/96/images/a52a20dd-7b8e-46be-86a0-dda86b0953fc/99-300.png'),
            (default, 'https://feeds.megaphone.fm/replyall', 'Reply All', 'Gimlet', '"''A podcast about the internet'' that is actually an unfailingly original exploration of modern life and how to survive it." - The Guardian. Hosted by PJ Vogt and Alex Goldman, from Gimlet.', 'https://images.megaphone.fm/_FDido6HoKbp_S5zoGyfMNxqbNgd4Qkn3IUnuObAV5A/plain/s3://megaphone-prod/podcasts/05f71746-a825-11e5-aeb5-a7a572df575e/image/uploads_2F1591157139331-y9ku7q9xzyq-9ab64ecee1420b68b238691e2d35b287_2FReplyAll-2019.jpg'),
            (default, 'http://podcasts.joerogan.net/feed', 'Joe Rogan (Podcast Site)', null, null, null);
        """)
print("inserted.\nInserting parent categories... ", end='', flush=True)

cur.execute("""insert into categories values 
        (default, 'Education'),
        (default, 'History'),
        (default, 'News'),
        (default, 'Arts'),
        (default, 'Technology'),
        (default, 'Society & Culture');
        """)
print("inserted.\nComitting... ", end='', flush=True)
conn.commit()
print("comitted.\nSelecting categories ids and inserting child categories... ", end='', flush=True)

cur.execute("select id from categories where name='Arts';")
cid = cur.fetchone()[0]
cur.execute("insert into categories values (default, 'Design', %s);", (cid,))

cur.execute("select id from categories where name='Society & Culture';")
cid = cur.fetchone()[0]
cur.execute("insert into categories values (default, 'Documentary', %s);", (cid,))
print("selected and inserted.\nComitting... ", end='', flush=True)
conn.commit()
print("comitted.")

print("selecting category & podcast ids... ", end='', flush=True)
cur.execute("select id, title from podcasts;")
podcastRecords = cur.fetchall()
podcasts = {}
for podcast in podcastRecords:
    podcasts[podcast[1]] = podcast[0]

cur.execute("select id, name from categories;")
categoryRecords = cur.fetchall()
categories = {}
for category in categoryRecords:
    categories[category[1]] = category[0]

print("selected. Categories are:")
print(categories)
print("podcasts are:")
print(podcasts)
print("inserting into podcastCategories...",end='',flush=True)

cur.execute("insert into podcastCategories values (%s,%s);", (podcasts["Hello Internet"], categories["Education"]))
cur.execute("insert into podcastCategories values (%s,%s);", (podcasts["Hardcore History"], categories["History"]))
cur.execute("insert into podcastCategories values (%s,%s);", (podcasts["Chapo Trap House"], categories["News"]))
cur.execute("insert into podcastCategories values (%s,%s);", (podcasts["99% Invisible"], categories["Arts"]))
cur.execute("insert into podcastCategories values (%s,%s);", (podcasts["99% Invisible"], categories["Design"]))
cur.execute("insert into podcastCategories values (%s,%s);", (podcasts["Reply All"], categories["Technology"]))
cur.execute("insert into podcastCategories values (%s,%s);", (podcasts["Reply All"], categories["Society & Culture"]))
cur.execute("insert into podcastCategories values (%s,%s);", (podcasts["Reply All"], categories["Documentary"]))

print("inserted")

print("inserting episode guids into episodes...", end='', flush=True)
cur.execute("insert into episodes values (%s, '52d66949e4b0a8cec3bcdd46:52d67282e4b0cca8969714fa:5e58de8a37459e0d069efda0');", (podcasts["Hello Internet"],))
cur.execute("insert into episodes values (%s, '52d66949e4b0a8cec3bcdd46:52d67282e4b0cca8969714fa:5e29c894361f630aaf01c469');", (podcasts["Hello Internet"],))

cur.execute("insert into episodes values (%s, 'http://traffic.libsyn.com/dancarlinhh/dchha65_Supernova_in_the_East_IV.mp3');", (podcasts["Hardcore History"],))
cur.execute("insert into episodes values (%s, 'http://traffic.libsyn.com/dancarlinhh/dchha64_Supernova_in_the_East_III.mp3');", (podcasts["Hardcore History"],))

cur.execute("insert into episodes values (%s, 'tag:soundcloud,2010:tracks/905365285');", (podcasts["Chapo Trap House"],))
cur.execute("insert into episodes values (%s, 'tag:soundcloud,2010:tracks/901319959');", (podcasts["Chapo Trap House"],))

cur.execute("insert into episodes values (%s, 'prx_96_d0e54846-eb8f-486a-b10b-f6764469f028');", (podcasts["99% Invisible"],))
cur.execute("insert into episodes values (%s, 'prx_96_3657a2b6-10a1-4580-8cce-ca8aff53b177');", (podcasts["99% Invisible"],))


cur.execute("insert into episodes values (%s, 'c14e79d0-e2c3-11e9-be80-8b8c640993e8');", (podcasts["Reply All"],))
cur.execute("insert into episodes values (%s, '2ae7f282-33ef-11ea-b18b-0f97aef9b5a6');", (podcasts["Reply All"],))

cur.execute("insert into episodes values (%s, 'http://podcasts.joerogan.net/?post_type=podcasts&p=10128');", (podcasts["Joe Rogan (Podcast Site)"],))
cur.execute("insert into episodes values (%s, 'http://podcasts.joerogan.net/?post_type=podcasts&p=10124');", (podcasts["Joe Rogan (Podcast Site)"],))

print("inserted")

print("selecting user ids from users...", end='', flush=True)
cur.execute("select id, username from users")
userRecords = cur.fetchall()
users = {}
for user in userRecords:
    users[user[1]] = user[0]
print("selected")
print("inserting into subscriptions...", end='', flush=True)

cur.execute("insert into subscriptions values (%s, %s);", (users["tom"],podcasts["Hello Internet"]))
cur.execute("insert into subscriptions values (%s, %s);", (users["tom"],podcasts["Hardcore History"]))
cur.execute("insert into subscriptions values (%s, %s);", (users["tom"],podcasts["Chapo Trap House"]))
cur.execute("insert into subscriptions values (%s, %s);", (users["tom"],podcasts["Joe Rogan (Podcast Site)"]))
cur.execute("insert into subscriptions values (%s, %s);", (users["tom"],podcasts["99% Invisible"]))

cur.execute("insert into subscriptions values (%s, %s);", (users["pawanjot"],podcasts["Hello Internet"]))
cur.execute("insert into subscriptions values (%s, %s);", (users["pawanjot"],podcasts["Hardcore History"]))
cur.execute("insert into subscriptions values (%s, %s);", (users["pawanjot"],podcasts["Joe Rogan (Podcast Site)"]))

cur.execute("insert into subscriptions values (%s, %s);", (users["justin"],podcasts["99% Invisible"]))
cur.execute("insert into subscriptions values (%s, %s);", (users["justin"],podcasts["Hardcore History"]))
cur.execute("insert into subscriptions values (%s, %s);", (users["justin"],podcasts["Joe Rogan (Podcast Site)"]))

cur.execute("insert into subscriptions values (%s, %s);", (users["nich"],podcasts["Chapo Trap House"]))
cur.execute("insert into subscriptions values (%s, %s);", (users["nich"],podcasts["99% Invisible"]))

print("inserted")
print("comitting... ", end='', flush=True)

conn.commit()

print("comitted.")

cur.close()
conn.close()

