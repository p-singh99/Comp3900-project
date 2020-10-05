# Database Details

Hostname: ```polybius.bowdens.me```
Port: ```5432```
Database: ```ultracast```
Username: ```brojogan```
Password: ```GbB8j6Op```


## Connecting with psql
```psql --host=polybius.bowdens.me --port=5432 --username=brojogan ultracast```

Then enter password as above

## psycopg2

### Install psycopg2
``` sudo apt install python3-pyscopg2```

### Connecting with psycopg2

```
import psycopg2

conn = psycopg2.connect(dbname="ultracast", user="brojogan", password="GbB8j6Op", host="polybius.bowdens.me", port=5432)

cur = conn.cursor()

cur.execute("SELECT * from test");

print(cur.fetchall())

cur.close()
conn.close()
```

