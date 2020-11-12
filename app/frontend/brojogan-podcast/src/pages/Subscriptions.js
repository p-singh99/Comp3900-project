import React, { useState, useEffect } from 'react';
import Helmet from 'react-helmet';
import ReactDOM from 'react-dom';
import {fetchAPI} from '../authFunctions';
import PodcastCards from '../components/PodcastCards';
import './../css/SearchPage.css';

function Subscriptions() {
  const [podcasts, setPodcasts] = useState();

  useEffect(() => {
    setPodcasts();
    fetchAPI(`/subscriptions`,'get',null)
      .then(podcasts => {
          setPodcasts(podcasts);
        }
      );
  }, []);
  // can't use <Link> within ReactDOM.render() 

  return (
    <div id="subscription-page-div">
      <Helmet>
        <title>BroJogan Podcasts - Subscriptions</title>
      </Helmet>

      {(() => {
        if (podcasts && podcasts.length > 0) {
          return (
            <PodcastCards
              heading={`Subscriptions`}
              podcasts={podcasts}
              options={{subscribeButton: true}}
            />)
        } else if (podcasts) {
          return "You aren't subscribed to any podcasts.";
        } else {
          return "Loading...";
        }
      })()}
    </div>
  )
}

export default Subscriptions;
