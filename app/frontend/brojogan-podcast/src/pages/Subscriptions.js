import React, { useState, useEffect } from 'react';
import Helmet from 'react-helmet';
import {fetchAPI} from '../authFunctions';
import PodcastCards from '../components/PodcastCards';
import './../css/SearchPage.css';

function Subscriptions() {
  const [podcasts, setPodcasts] = useState();

  useEffect(() => {
    setPodcasts();
    fetchAPI(`/users/self/subscriptions`,'get',null)
      .then(podcasts => {
          setPodcasts(podcasts);
        }
      );
  }, []);

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
          return <h4>Loading...</h4>;
        }
      })()}
    </div>
  )
}

export default Subscriptions;
