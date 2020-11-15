import React, { useState, useEffect } from 'react';
import { Helmet } from 'react-helmet';

import PodcastCards from './../components/PodcastCards';
import { fetchAPI } from './../authFunctions';

import './../css/SearchPage.css';

// for Search, the backend returns a list of results of form {todo}
// And this component uses PodcastCards and passes it the list of podcasts
// Each card then fetches the details for the podcast with the id it is given, and displays the details
// when a link to a podcast description page is clicked, if the podcast details have finished loading, then they will be passed to the Description page
// so they don't have to be fetched again
export default function Search() {
  const [podcasts, setPodcasts] = useState();
  const [titleQuery, setTitleQuery] = useState("");
  // const [error, setError] = useState();

  // on page load, get query from url. then get and display query results
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
        // can't just display an error, because this will also be called on request aborting as well as actual error
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
