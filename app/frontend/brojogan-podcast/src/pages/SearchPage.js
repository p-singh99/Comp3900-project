import React, { useState, useEffect } from 'react';
import { Helmet } from 'react-helmet';

import PodcastCards from './../components/PodcastCards';
import { fetchAPI } from './../authFunctions';

import './../css/SearchPage.css';

export default function Search() {
  const [podcasts, setPodcasts] = useState();
  const [titleQuery, setTitleQuery] = useState("");
  // const [error, setError] = useState();

  // on page load, get query from url and get then display query results
  useEffect(() => {
    // setError();

    const controller = new AbortController();

    setPodcasts();
    const query = window.location.search.substring(1);
    setTitleQuery(query);
    console.log(`podcasts at start of ${query}: `, podcasts);
    console.log(`starting query ${query}`)

    // Need to send with token if logged in so backend can track searches
    fetchAPI('/podcasts?search_query=' + query + '&offset=0&limit=50', 'get', null, controller.signal)
      .then(podcasts => {
        setPodcasts(podcasts);
      })
      .catch(err => {
        // do something
        // can't just display an error, because this will also be called on request aborting
        console.log(err);
        // setError("Network or other error");
      });

      return function cleanup() {
        console.log("aborting search request");
        controller.abort();
        // abort pending request so that search results from this query don't show up for the next query?
      }
  }, [window.location.search]); // for reloading when something is searched from the search page

  return (
    <div id="search-page-div">
      <Helmet>
        <title>{titleQuery} - BroJogan Podcasts</title>
      </Helmet>

      {(() => {
        if (podcasts && podcasts.length > 0) {
          return (
            <PodcastCards
              heading={`Search Results`}
              podcasts={podcasts}
            />)
        } else if (podcasts) {
          return "No results";
        // } else if (error) {
        //   return error;
        } else {
          return "Loading";
        }
      })()}
    </div>
  )
}
