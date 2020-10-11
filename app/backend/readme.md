| HTTP Method |  Endpoint                                                    | Request body                          | Response body | Action                  |
|-------------|--------------------------------------------------------------|---------------------------------------|---------------|-------------------------|
| POST        | `/users`                                                     | Form: “username”, “email”, "password” | {“token : “”}, 201<br>{“error “ :  “Username already exists”}, {“error “ :  “Email already exists”}, 409 | Login |
| POST        | `/login`                                                     | Form: "username", "password"          | {“token : “”}, 201<br>{“error” : “Login Failed”}, 401 | Sign up |
| GET         | `/podcasts/<podcastID>`                                      |                                       |               | Returns podcast details - RSS feed URL, rating |
| GET         | `/podcasts?q=<query>&offset=<startNum>&limit=<limitNum>`     |                                       |               | Search. Request `limitNum` results starting at result number `startNum` |  
