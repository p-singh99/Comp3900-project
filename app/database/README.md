# Database Details
**Local**
To set up a local database you will need to have postgres installed. I used postgres12 for this but any recent version should be fine.

Create the database using createdb:  
```createdb ultracast```

Then get the database backup file from google drive [here](https://drive.google.com/drive/folders/1xeYmOVXuIgHIw4TC7uIIG3T4KBqSYRng?usp=sharing)

Finally create the database using the sql file:  
```psql ultracast < db.sql```

**Polybius (remote db, shared by team)**  
Hostname: ```polybius.bowdens.me```  
Port: ```5432```  
Database: ```ultracast```  
Username: ```brojogan```  
Password: ```GbB8j6Op```  


## Connecting to polybius with psql
**Polybius**  
```psql --host=polybius.bowdens.me --port=5432 --username=brojogan ultracast```

Then enter password as above

**Local**  
```psql ultracast```

## psycopg2

### Install psycopg2
``` sudo apt install python3-pyscopg2```

### Connecting with psycopg2

**Polybius**  
```python3
import psycopg2

conn = psycopg2.connect(dbname="ultracast", user="brojogan", password="GbB8j6Op", host="polybius.bowdens.me", port=5432)

cur = conn.cursor()

cur.execute("SELECT * from test");

print(cur.fetchall())

cur.close()
conn.close()
```

**Local**
```python3
import psycopg2

conn = psycopg2.connect(dbname="ultracast")

cur = conn.cursor()
```

## Database Schema

### Users
Column      |   Type    |   Details
------------|-----------|------
id          | serial    | Primary key. Use 'default' when inserting to auto generate
username    |   text    | Can only contain the characters a-z, 0-9, _, and -. Must contain 3 or more characters. Must be unique. Must not be null. The frontend and/or backend must convert uppercase characters to lowercase characters.
email       |   text    | Must be unique. Must not be null. Must be an (approximately) valid email with only lowercase characters. The frontend and/or backend must convert uppercase characters to lowercase characters.
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
parentCateogry | integer | id of the parent category. May be null. Must be a valid id from the categories table.

The categories table exists to keep track of all known podcast categories. When a new podcast is added to the app by RSS Feed, the application must check if any of its categories are new and if so, add them to the categories table.

### Podcasts
Column      |   Type    |   Details
------------|-----------|----------
id          | serial    | Primary key. Use 'defualt' when inserting to auto generate
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
guid        | text      | Must be unique, must not be null. The RSS feed should specify a guid for each episode, otherwise the application must generate one.

**Primary Key** is (podcastId, guid)  
When a user listens or interacts with an episode from a podcast for the first time, the application should check if it is in the database. If not it should be added with the appropriate podcastId and guid.

### Listens
Column      |   Type    |   Details
------------|-----------|----------
userId      | integer   | references Users(id)
podcastId   | integer   | (podcastID, episodeGuid) references Episodes(podcastId, guid)
episodeGuid | integer | "   "
listenDate  | timepstamp | must not be null. Should be updated by the application when the user begins or resumes listening to an episode
timestamp   | integer   | must not be null. The number of seconds a user is through an episode.

**Primary Key** is (userId, pocastId, episodeGuid)

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
podcastId   | integer   | (podcastId, episodeGuid) references Episodes (podcastId, guid)
episodeGuid | integer | "   "
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

#### subscribed\_podcasts\_for\_user(\_userId integer)
A function that returns a table of all the podcasts a particular user is subscribed to.
**Returns**: A query that contains all of the podcasts that a user is susbcribed to (all of the columns associated with podcasts, not just its id)
**Usage**: ```select * from subscribed_podcasts_for_user((select id from users where username='Tom'));```
**Return example**:
```
id | rssfeed | title | author | description | thumbnail
---+---------+-------+--------+-------------+----------
		... podcasts ...
```

#### count\_subscriptions\_for\_podcast(\_podcastId integer)
A function that returns a table simply containing the number of subscribers for a particular podcast
**Returns**: A query that contains only 1 row and column: an integer of the number of subscribers
**Usage**: ```select * from count_subscriptions_for_podcast((select id from podcasts where title='Chapo Trap House'));```
**Return example**:
```
subscribers
-----------
         2
```


### Views
#### NumSubscribersPerPodcast
Column      |   Type    |   Details
------------|-----------|----------
podcastId   | integer   | references Podcasts (id)
subscribers | integer   | the number of users who are subscribed to the podcast

## Test Data (populate.py and depopulate.py)
### populate.py
**[populate.py](populate.py)** is a python script that connects to the database and adds test data. The data is sourced from actual podcast RSS feeds so it should be representative of what will actually be in the database. The script does a sanity check that the database is empty by checking there is nothing in the Users table before it executes. The script currently has test data for:
* Users (5 users)
* Podcasts (6 podcasts)
* Categories (6 categories [2 of whom are subcategories])
* PodcastCategories (relating categories to podcasts)
* Episode (2 episodes per podcast)
* Subscriptions (relating podcasts to users, a varying number of subscriptions per user and users per podcast)

**[depopulate.py](depopulate.py)** is a python script that connects to the database and deletes everything from all of the tables that populate.py touches. It prompts the user for confirmation that they actually want to delete everything in the database before it executes anything.

**Suggested Usage**: ```$ python3 depopulate.py && python3 populate.py```
