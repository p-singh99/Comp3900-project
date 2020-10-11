### Sprint 1
| HTTP Method |  Endpoint                                                    | Request body                          | Response body | Action                  |
|-------------|--------------------------------------------------------------|---------------------------------------|---------------|-------------------------|
| POST        | `/users`                                                     | Form: “username”, “email”, "password” | {“token : “”}, 201<br>{“error “ :  “Username already exists”}, {“error “ :  “Email already exists”}, 409 | Login |
| POST        | `/login`                                                     | Form: "username", "password"          | {“token : “”}, 201<br>{“error” : “Login Failed”}, 401 | Sign up |
| GET         | `/podcasts/<podcastID>`                                      |                                       |               | Returns podcast details - RSS feed URL, rating |
| GET         | `/podcasts?q=<query>&offset=<startNum>&limit=<limitNum>`     |                                       |               | Search. Request `limitNum` results starting at result number `startNum` |  

### Future endpoints, subject to change
| HTTP Method |  Endpoint                                                    | Request body         | Response body | Action                  |
|-------------|--------------------------------------------------------------|----------------------|---------------|-------------------------|
| POST        | `/podcasts`                                                  | `{"rss": <rsslink>}` |               | Add a podcast   |
| GET         | `/users/self/podcasts/<podcastID>/episodes/<episodeID>/time` |                      |               | Return time progress in episode |
| PUT         | `/users/self/podcasts/<podcastID>/episodes/<episodeID>/time` | `{"time": <time>}`   |               | Update time progress in episode, and also listening history |
| PUT         | `/users/self/podcasts/<podcastID>/rating`                    | `{"rating": <rating>}` |             | Update rating for podcast |
| GET         | `/users/self/podcasts/<podcastID>`                           |                      |               | Get user's podcast rating, whether subscribed |
| POST        | `/users`                                                     | `{"email": <email>, "username": <username>, "password": <password>}` | | Create account |
| DELETE      | `/users/self`                                                |                      |               | Delete account |
| PUT         | `/users/self/password`                                       | `{"oldpassword": <oldpassword>, "newpassword": <newpassword>}` | |                                                                 Change password |
| PUT         | `/users/self/email`                                          | `{"password": <password>, "newemail": <email>}` | |                                                                                          | Change email address |
| POST        | `/users/passwordreset`                                       | `{"email": <emailaddress>}` | |                                                                                           Request password reset |
| POST        | `/users/self/subscriptions`                                  | `{"id": <podcastID>}` | | Subscribe to a podcast |
| DELETE      | `/users/self/subscriptions/<podcastID>`                      |                       | | Unsubscribe from a podcast |
| GET         | `/users/self/subscriptions`                                  |                       | | Get list of subscribed podcasts - IDs and maybe the actual podcast info as well, to save an RTT from follow up requests? |
| GET         | `/users/self/rejectedrecommendations`                        |                       | | Get list of rejected podcast recommendations |
| POST        | `/users/self/rejectedrecommendations`                        | `{"id": <podcastID>}` | | Add rejected recommendation |
| GET         | `/users/self/history?offset=<startNum>&limit=<limitNum>&podcast=<podcastID>` |       | | Get listening history. With podcast set, returns listening history for a particular podcast. |
