import React, {useState} from 'react';
import {Link} from 'react-router-dom';
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
  const [windowDimensions, setWindowDimensions] = useState({});
  const newUser = props.location.state ? props.location.state.newUser : false;
  
  const handleResize = () => {
    console.log(`Resized to: ${window.innerWidth} X ${window.innerHeight}`);
  }
  
  window.addEventListener('resize', handleResize);
  return (
    <div>
      <Helmet>
        <title>Brojogan Podcasts</title>
      </Helmet>

      <div id="new-user-login">
        <div id="message">
          <p id="message-1">
            {/* <h4> */}
              Subscribe And Get Notified
              {/* Create an account with us */}
            {/* </h4> */}
          </p>
          <p id="message-2">
              Create an account with us <br/>
          </p>
          <p id="message-3">
              Its Free!
          </p>
          <div id="form-homePage">
            <Link to={{ pathname: `/login`}}>
              <button type="button" id="login-homePage" className="homePage-btn">
                Login
              </button>
            </Link>
            <Link to={{ pathname: `/signup`}}>
              <button type="button" id="signup-homePage" className="homePage-btn">
                Sign Up
              </button>
            </Link>
          </div>
        </div>
      </div>

      <h1>
        {/* {welcome(newUser)} */}
      </h1>
      {/* < SubscriptionPanel/> */}
      {/* <TopPodcasts /> */}
    </div>
  );
}

export default Home;