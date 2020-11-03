import React from 'react';
import ReactDOM from 'react-dom';
import { API_URL } from './../constants';
import PodcastCards from '../components/PodcastCards';
import './../css/SearchPage.css';


export default function Search(podcasts) {
  var query = window.location.search.substring(1);
  console.log(`starting query ${query}`)
  fetch(`${API_URL}/podcasts?search_query=` + query + '&offset=0&limit=50', { method: 'get' })
    .then(resp => resp.json())
    .then(podcasts => {
      // const podcastList = document.getElementById("podcast-list");
      // let i = 0;
      // let cards = [];
      // let podcastTitles = [];
      // let podcastDescriptions = [];
      // for (let podcast of podcasts) {
      //   console.log(`I is: ${i}`);
      //   podcastTitles.push(podcast.title);
      //   podcastDescriptions.push(podcast.description);
      // }

      ReactDOM.render(
        <PodcastCards
          heading={`Search Results`}
          podcasts={podcasts}
        />,
        document.getElementById('search-page-div')
      );
    });
  return (
    <div id="search-page-div"></div>
  )
}
