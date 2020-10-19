import React from 'react';
import { isLoggedIn } from './../auth-functions'
import { Helmet } from 'react-helmet';

function Home() {
  return (
    <div>
      <Helmet>
        <title>Brojogan Podcasts</title>
      </Helmet>

      <h1>
        {isLoggedIn()
          ? <p>Welcome back, {window.localStorage.getItem("username")}</p>
          : <p>Welcome to the Homepage</p>
        }
      </h1>
    </div>
  );
}

export default Home;