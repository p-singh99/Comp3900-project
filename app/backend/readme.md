## How to run
```bash
python3 -m venv .env  
source .env/bin/activate
python3 -m pip install -r requirements.txt
FLASK_APP=main.py flask run
```

## API Documentation

### Implemented
| HTTP Method |  Endpoint                                                    | Request body                          | Response body | Action                  |
|-------------|--------------------------------------------------------------|---------------------------------------|---------------|-------------------------|
| POST        | `/users`                                                     | Form: “username”, “email”, "password” | `{“token: “”}`, 201<br>`{“error“ :  “Username already exists”}`, `{“error“ :  “Email already exists”}`, 409 | Sign up |
| POST        | `/login`                                                     | Form: "username", "password"          | `{“token: “”}`, 200<br>`{“error” : “Login Failed”}`, 401 | Login |
| GET         | `/podcasts/<podcastID>`                                      |                                       | `{"xml": xml text}`, 200<br>`{}`, 404<br>`{}`, 500 | Returns podcast details - RSS feed URL, rating |
| GET         | `/podcasts?search_query=<query>&offset=<startNum>&limit=<limitNum>`     |                 | `[{"subscribers": subs, "title": title, "author" : author, "description" : desc}, #]`, 200<br> `[]`, 200              | Search. Request `limitNum` results starting at result number `startNum` |  
| DELETE      | `/self/settings`                                                |                      |               | Delete account |
| PUT         | `/self/settings`                                       | `{"oldpassword": <oldpassword>, "newpassword": <newpassword>, "newemail":<email>}` | |                                                               Change password and/or email |  
| GET        | `/self/history/<pagenumber>`                                  |                                       | {"history": [{xml, guid}]}, 200<br>`{“error“ :  “bad request”}`, 400 | Check user history |

### Future endpoints, subject to change
| HTTP Method |  Endpoint                                                    | Request body         | Response body | Action                  |
|-------------|--------------------------------------------------------------|----------------------|---------------|-------------------------|
| POST        | `/podcasts`                                                  | `{"rss": <rsslink>}` |               | Add a podcast   |
| GET         | `/self/podcasts/<podcastID>/episodes/<episodeID>/time` |                      |               | Return time progress in episode |
| PUT         | `/self/podcasts/<podcastID>/episodes/<episodeID>/time` | `{"time": <time>}`   |               | Update time progress in episode, and also listening history |
| PUT         | `/self/ratings/<podcastID>`                    | `{"rating": <rating>}` |             | Update rating for podcast |
| GET         | `/self/podcasts/<podcastID>`                           |                      |               | Get user's podcast rating, whether subscribed |
| POST        | `/passwordreset`                                       | `{"email": <emailaddress>}` | |                                                                                           Request password reset |
| POST        | `//self/subscriptions`                                  | `{"id": <podcastID>}` | | Subscribe to a podcast |
| DELETE      | `//self/subscriptions/<podcastID>`                      |                       | | Unsubscribe from a podcast |
| GET         | `//self/subscriptions`                                  |                       | | Get list of subscribed podcasts - IDs and maybe the actual podcast info as well, to save an RTT from follow up requests? |
| GET         | `/self/recommendations`                        |                       | | Get list of podcast recommendations |
| GET         | `/self/rejectedrecommendations`                        |                       | | Get list of rejected podcast recommendations |
| POST        | `/self/rejectedrecommendations`                        | `{"id": <podcastID>}` | | Add rejected recommendation |
| GET         | `/self/history/<podcastID>` |   `{"rating": rating}`    | | Get listening history. With podcast set, returns listening history for a particular podcast. |
