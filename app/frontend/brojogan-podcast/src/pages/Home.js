import React from 'react';
import { isLoggedIn, getUsername } from './../auth-functions'
import { Helmet } from 'react-helmet';

function Home() {
  return (
    <div>
      <Helmet>
        <title>Brojogan Podcasts</title>
      </Helmet>

      <h1>
        {isLoggedIn()
          ? <p>Welcome back, {getUsername()}</p>
          : <p>Welcome to the Homepage</p>
        }
      </h1>
    </div>
  );
}

export default Home;