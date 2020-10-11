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

```python3
import psycopg2

conn = psycopg2.connect(dbname="ultracast", user="brojogan", password="GbB8j6Op", host="polybius.bowdens.me", port=5432)

cur = conn.cursor()

cur.execute("SELECT * from test");

print(cur.fetchall())

cur.close()
conn.close()
```

## Database Schema

### Users
Column      |   Type    |   Details
------------|-----------|------
id          | integer   | Primary key. A unique id should be generated by the app
username    |   text    | Can only contain the characters A-Z, a-z, 0-9, _, and -. Must contain 3 or more characters. Must be unique. Must not be null.
email       |   text    | Must be unique. Must not be null. Application should check that the email is valid becuase the database does not.
hashedPassword |    text    | Intended for storing the hashed password of the user with salt. Must not be null.

### SearchQueries
Column      |   Type    |   Details
------------|-----------|----------
userId      | integer   | references Users(id)
query       | text      | The search term entered by the user. Must not be null
searchDate  | timestamp | The time the search was made. Must not be null

The SearchQueries table exists to keep a record of all searches made by a user. It keeps track of the search query and when it was searched for.

**Primary Key** is (userId, query, searchDate)

### Categories
Column      |   Type    |   Details
------------|-----------|----------
id          | serial    | Auto generated primary key.
name        | text      | Name of the category. Cannot be null

The categories table exists to keep track of all known podcast categories. When a new podcast is added to the app by RSS Feed, the application must check if any of its categories are new and if so, add them to the categories table.

### Podcasts
Column      |   Type    |   Details
------------|-----------|----------
id          | integer   | Primary key. The application must generate a unique ID for the podcast when it is added.
rssFeed     | text      | Must not be unique and not null. The application must verify the RSS feed is legitimate
title       | text      | Must not be null. The application should extract the title from the podcast feed when adding it to the database
author      | text      | The application should extract the author from the podcast feed when adding it to the database
description | text      | The application should extract the description from the podcast feed when adding it to the database.
thumbnail   | text      | A link to the podcast thumbnail. The application should extract the thumbnail from the podcast feed when adding it to the database.

The main thing the podcasts table stores is the rssFeed. However also stores some metadata about the podcast for the purpose of searching through the podcasts.

### PodcastCategories

Column      |   Type    |   Details
------------|-----------|----------
podcastId   | integer   | references Podcasts(id)
categoryId  | integer   | references Categories(id)

**Primary Key** is (podcastId, categoryId)

### Episodes
Column      |   Type    |   Details
------------|-----------|----------
podcastId   | integer   | references Podcasts(id)
sequence    | integer   | Must be > 0. The sequence is the episode number. So the first episode in a podcast would have the sequence 1. 

**Primary Key** is (podcastId, sequence)  
When a user listens or interacts with an episode from a podcast for the first time, the application should check if it is in the database. If not it should be added with the appropriate podcastId and sequence.

### Listens
Column      |   Type    |   Details
------------|-----------|----------
userId      | integer   | references Users(id)
podcastId   | integer   | (podcastID, episodeSequence) references Episodes(podcastId, sequence)
episodeSequence | integer | "   "
listenDate  | timepstamp | must not be null. Should be updated by the application when the user begins or resumes listening to an episode
timestamp   | integer   | must not be null. The number of seconds a user is through an episode.

**Primary Key** is (userId, pocastId, episodeSequence)

### Subscriptions
Column      |   Type    |   Details
------------|-----------|----------
userId      | integer   | references Users (id)
podcastId   | integer   | references Podcasts (id)

**Primary Key** is (userId, podcastId)

### PodcastRatings
Column      |   Type    |   Details
------------|-----------|----------
userId      | integer   | references Users (id)
podcastId   | integer   | references Podcasts (id)
rating      | integer   | Must not be null. Must be between 1 and 5 (inclusive)

**Primary Key** is (userId, podcastId)

### EpisodeRatings

Column      |   Type    |   Details
------------|-----------|----------
userId      | integer   | references Users (id)
podcastId   | integer   | (podcastId, episodeSequence) references Episodes (podcastId, sequence)
episodeSequence | integer | "   "
rating      | integer   | Must not be null. Must be between 1 and 5 (inclusive)

### RejectedRecommendations
Column      |   Type    |   Details
------------|-----------|----------
userId      | integer   | references Users (id)
podcastId   | integer   | references Podcasts (id)

**Primary Key** is (userId, podcastId)

### Functions
#### match\_category\_and\_podcast(\_podcast text, \_category text)
This function is intended to be used to easily insert tuples into the podcastCategories table. For instance, ```insert into podcastCategories select * from match_category_and_podcast('podcast', 'category');``` would insert a tuple with the id of the podcast named 'podcast' and the id of a category named 'category'.

**Returns**: A query that contains a podcastId associated with the podcast name and a categoryId associated with the category name. If either don't exist, nothing is returned.  
**Usage**: ```select * from match_category_and_podcast('podcast name', 'category name');```
**Return example**:
```
podcastId  |  categoryId 
-----------+------------
     5     |     3
```

#### match\_category\_and\_parent(\_category text, \_parent text)
This function is intended to be used to easily insret tuples into the categories table when a parent of the category being inserted is needed. For instance, ```insert into categories select * from match_category_and_parent('new category', 'parent category');``` would insert a tuple with the name 'new category' and the id of the category with the name 'parent category' as the parentCategory. The new id for the category is also automatically generated in the function.

**Returns**: A query that contains a new valid id for the new category, the name of the new category, and the id of the parent category.  
**Usage**: ```select * from match_category_and_parent('new category', 'parent category');```  
**Return example**: 
```
id |  name   | parentCategory
---+---------+---------------
 3 | 'Books' | 2
```

 