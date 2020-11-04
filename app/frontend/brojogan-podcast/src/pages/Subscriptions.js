import React, { useState, useEffect } from 'react';
import Helmet from 'react-helmet';
import ReactDOM from 'react-dom';
import {fetchAPI} from '../auth-functions';
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


// function Subscriptions() {
//   fetchAPI(`/subscriptions`,'get',null)
//     .then(podcasts => {
//       let i = 0;
//       let cards = [];
//       let podcastTitles = [];
//       let podcastDescriptions = [];
//       for (let p of podcasts) {
//         console.log(`I is: ${i}`);
//         podcastTitles.push(p.title);
//         podcastDescriptions.push(p.description);
//       }

//       ReactDOM.render(
//         <PodcastCards
//           heading={`Subscriptions`}
//           podcasts={podcasts}
//         />,
//         document.getElementById('subscription-page-div')
//       );
//     });

//   return (
//     <div id = "subscription-page-div"></div>
//   )
// }

export default Subscriptions;
