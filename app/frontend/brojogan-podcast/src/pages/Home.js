import React from 'react';
import { isLoggedIn } from './../auth-functions'

function Home() {
  if (isLoggedIn()) {
    return (
      <div>
        <h1>Welcome back, {window.localStorage.getItem("username")}</h1>
      </div>
    );
  } else {
    return (
      <div>
        <h1>Welcome to the Homepage</h1>
      </div>
    );
  }
}

export default Home;