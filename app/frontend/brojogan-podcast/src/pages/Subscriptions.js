import React from 'react';
import ReactDOM from 'react-dom';
import {API_URL} from './../constants';
import {fetchAPI} from '../auth-functions';
import PodcastCards from '../components/PodcastCards';
import './../css/SearchPage.css';

function Subscriptions() {
  fetchAPI(`/subscriptions`,'get',null)
    .then(podcasts => {
      let i = 0;
      let cards = [];
      let podcastTitles = [];
      let podcastDescriptions = [];
      for (let p of podcasts) {
        console.log(`I is: ${i}`);
        podcastTitles.push(p.title);
        podcastDescriptions.push(p.description);
      }

      ReactDOM.render(
        <PodcastCards
          heading={`Subscriptions`}
          podcasts={podcasts}
        />,
        document.getElementById('subscription-page-div')
      );
    });

  return (
    <div id = "subscription-page-div"></div>
  )
}

export default Subscriptions
