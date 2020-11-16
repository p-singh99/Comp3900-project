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
| POST        | `/users`                                                     | Form: “username”, “email”, "password” | `{“token: “”, "user": username}`, 201<br>`{“error“ :  “Username already exists”}`, `{“error“ :  “Email already exists”}`, 409 | Sign up |
| POST        | `/login`                                                     | Form: "username", "password"          | `{“token: “”, "user": username}`, 200<br>`{“error” : “Login Failed”}`, 401 | Login |
| GET         | `/podcasts/<podcastID>`                                      |                                       | `{"xml": xml, "id": podcastid, "subscription": bool, "subscribers": subscribers, "rating": rating}, 200`, 200<br>`{}`, 404<br>`{}`, 500 | Returns podcast details - RSS feed URL, rating |
| GET         | `/podcasts?search_query=<query>`     |   |`{"subscribers" : subscribers, "title" : title, "author" : author, "description" : description, "pid" : podcastid, "thumbnail" : thumbnail, "rating" : rating}`, 200 `[]`, 200              | Search. Request|  
| DELETE      | `/users/self/`                                                |                      |               | Delete account |
| PUT         | `/users/self/settings`                                       | `{"oldpassword": <oldpassword>, "newpassword": <newpassword>, "newemail":<email>}` | `{"data" : "success"}`, 200, `{"error" : "wrong password"}` 400, `{"error": "Email already exists"}`,400 `{"oldpassword": "Need old password"}`, 400 |                                                               Change password and/or email |  
| GET        | `/users/self/history/<pagenumber>`                                  |   `{"limit": <int>}`                                    | `{"history": [{"pid" : podcastid, "xml": xml, "episodeguid": guid, "listenDate": listendate, "timestamp": timestamp}]}`, 200<br>`{“error“ :  “bad request”}`, 400 | Check user history |
| GET         | `/users/self/podcasts/<podcastID>/episodes/<episodeID>/time` |                      |   `{"episodeGuid": guid, "listenDate": listendate, "timestamp": timestamp, "complete", <bool>}`, 200            | Return time progress in episode |
| PUT         | `/users/self/podcasts/<podcastID>/episodes/<episodeID>/time` | `{"time": <time>}`   |    `{"userId": user_id, "podcastId": podcastid "episodeGuid": guid, "listenDate": listendate, "timestamp": timestamp, "complete", <bool>}`, 200             | Update time progress in episode, and also listening history |
| PUT         | `/users/self/ratings/<podcastID>`                    | `{"rating": <rating>}` |       `{"rating": rating}`, 200      | Update rating for podcast |
| GET         | `/users/self/ratings/<podcastID>`                           |           `{rating: }`           |               | Get user's podcast rating, whether subscribed |
| POST        | `/passwordreset`                                       | `{"email": <emailaddress>}` | |                                                                                           Request password reset |
| POST        | `/users/self/subscriptions`                                  | `{"id": <podcastID>}` | | Subscribe to a podcast |
| DELETE      | `/users/self/subscriptions/<podcastID>`                      |                       | | Unsubscribe from a podcast |
| GET         | `/users/self/subscriptions`                                  |                       | | Get list of subscribed podcasts - IDs and maybe the actual podcast info as well, to save an RTT from follow up requests? |
| GET         | `/users/self/recommendations`                        |                       | `{"title": title, "thumbnail": thumbnail, "id": podcastid, "subs": subscribers, "eps": episodes, "rating": rating}` | Get list of podcast recommendations |
