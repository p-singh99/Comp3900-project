## How to run
```bash
python3 -m venv .env  
source .env/bin/activate
python3 -m pip install -r requirements.txt
FLASK_APP=main.py flask run
```

## API Documentation

### Implemented
| HTTP Method |  Endpoint                                                    | Request body                          | Response body, status | Action                  |
|-------------|--------------------------------------------------------------|---------------------------------------|---------------|-------------------------|
| POST        | `/users`                                                     | Form: “username”, “email”, "password” | `{“token: “”}`, 201<br>`{“error“ :  “Username already exists”}`, `{“error“ :  “Email already exists”}`, 409 | Sign up |
| POST        | `/login`                                                     | Form: "username", "password"          | `{“token: “”}`, 200<br>`{“error” : “Login Failed”}`, 401 | Login |
| GET         | `/podcasts/<podcastID>`                                      |                                       | `{"xml": xml text}`, 200<br>`{}`, 404<br>`{}`, 500 | Returns podcast details - RSS feed URL, rating |
| GET         | `/podcasts?search_query=<query>&offset=<startNum>&limit=<limitNum>`     |                 | `[{"subscribers": subscribers, "title": title, "author" : author, "description" : description, "pid": podcastID}]`, 200             | Search. Request `limitNum` results starting at result number `startNum` |  
| DELETE      | `/self/settings`                                                |                      |               | Delete account |
| PUT         | `/self/settings`                                       | `{"oldpassword": <oldpassword>, "newpassword": <newpassword>, "newemail":<email>}` | |                                                               Change password and/or email |  
| GET    | `/self/settings` | | {"email": email}, 200 | Return current settings ie email address
| GET        | `/self/history/<pagenumber>?limit=<pageSize>`                                  |                                       | {"history": [{xml, guid}]}, 200<br>`{“error“ :  “bad request”}`, 400 | Check user history |
| GET        | `/protected` | | 200 or 401 | Check if user token is valid - ie if user is logged in
| GET         | `/self/recommendations`                        |                       | | Get list of podcast recommendations |
| POST        | `/self/subscriptions`                                  | `{"id": <podcastID>}` | | Subscribe to a podcast |
| GET         | `/self/subscriptions`                                  |                       | | Get list of subscribed podcasts - IDs and maybe the actual podcast info as well, to save an RTT from follow up requests? |
| PUT         | `/self/ratings/<podcastID>`                    | `{"rating": <rating>}` |             | Update rating for podcast |
| GET         | `/self/ratings/<podcastID>` | | todo | Get user's current rating for a podcast
| GET         | `/self/podcasts/<podcastID>/episodes/time` |                      |    todo           | Return time progress in all episodes of the podcast |

### Future endpoints, subject to change
| HTTP Method |  Endpoint                                                    | Request body         | Response body | Action                  |
|-------------|--------------------------------------------------------------|----------------------|---------------|-------------------------|
| POST        | `/podcasts`                                                  | `{"rss": <rsslink>}` |               | Add a podcast   |
| PUT         | `/users/self/podcasts/<podcastID>/episodes/<episodeID>/time` | `{"time": <time>}`   |               | Update time progress in episode, and also listening history |
| GET         | `/users/self/podcasts/<podcastID>`                           |                      |               | Get user's podcast rating, whether subscribed |
| POST        | `/users/passwordreset`                                       | `{"email": <emailaddress>}` | |                                                         | DELETE      | `/self/subscriptions/<podcastID>`                      |                       | | Unsubscribe from a podcast |                    Request password reset |
| DELETE      | `/users/self/subscriptions/<podcastID>`                      |                       | | Unsubscribe from a podcast |
| GET         | `/users/self/subscriptions`                                  |                       | | Get list of subscribed podcasts - IDs and maybe the actual podcast info as well, to save an RTT from follow up requests? |
| POST        | `/users/self/subscriptions`                                  | `{"id": <podcastID>}` | | Subscribe to a podcast |
| GET         | `/users/self/rejectedrecommendations`                        |                       | | Get list of rejected podcast recommendations |
| POST        | `/users/self/rejectedrecommendations`                        | `{"id": <podcastID>}` | | Add rejected recommendation |
| GET         | `/users/self/history?offset=<startNum>&limit=<limitNum>&podcast=<podcastID>` |       | | Get listening history. With podcast set, returns listening history for a particular podcast. |
