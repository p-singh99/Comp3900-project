import React from 'react';
import { isLoggedIn, getUsername } from './../authFunctions'
import { Helmet } from 'react-helmet';
import SubscriptionPanel from './../components/SubscriptionPanel';
import TopPodcasts from '../components/TopPodcasts';
import './../css/Home.css';

// just an idea to try something
function welcome(newUser) {
  if (newUser) {
    return <p>Welcome to BroJogan Podcasts, {getUsername()}</p>
  } else if (isLoggedIn()) {
    return <p>Welcome back, {getUsername()}</p>
  } else {
    return <p>Welcome to the Homepage</p>
  }
}

function Home(props) {
  const newUser = props.location.state ? props.location.state.newUser : false;
  return (
    <div>
      <Helmet>
        <title>Brojogan Podcasts</title>
      </Helmet>

      {/* <div id="new-user-login">

      </div> */}

      <h1>
        {/* {welcome(newUser)} */}
      </h1>
      {/* < SubscriptionPanel/> */}
      <TopPodcasts />
    </div>
  );
}

export default Home;