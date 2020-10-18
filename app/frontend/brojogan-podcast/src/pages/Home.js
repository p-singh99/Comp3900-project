import React from 'react';
import { isLoggedIn } from './../auth-functions'
import { Helmet } from 'react-helmet';

function Home() {
  // change this
  if (isLoggedIn()) {
    return (
      <div>
         <Helmet>
          <title>Brojogan Podcasts</title>
        </Helmet>

        <h1>Welcome back, {window.localStorage.getItem("username")}</h1>
      </div>
    );
  } else {
    return (
      <div>
         <Helmet>
          <title>Brojogan Podcasts</title>
        </Helmet>
        
        <h1>Welcome to the Homepage</h1>
      </div>
    );
  }
}

export default Home;