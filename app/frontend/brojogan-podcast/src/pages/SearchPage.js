import React, { useState, useEffect } from 'react';
import { Helmet } from 'react-helmet';

import PodcastCards from './../components/PodcastCards';
import { fetchAPI } from './../authFunctions';

import './../css/SearchPage.css';

// for Search, the backend returns a list of results of form {subscribers, title, author, description, pid, title, rating, thumbnail}
// And this component uses PodcastCards and passes it the list of podcasts
// Each card then fetches the details for the podcast with the id it is given, and displays the details
// when a link to a podcast description page is clicked, if the podcast details have finished loading, then they will be passed to the Description page
// so they don't have to be fetched again
export default function Search() {
  const [podcasts, setPodcasts] = useState();
  const [titleQuery, setTitleQuery] = useState("");
  const [error, setError] = useState();

  // on page load, get query from url. then get and display query results
  useEffect(() => {
    setError(null);

    const controller = new AbortController();

    setPodcasts();
    const query = window.location.search.substring(1);
    setTitleQuery(query);

    // Need to send with token if logged in so backend can track searches
    fetchAPI('/podcasts?search_query=' + query + '&offset=0&limit=50', 'get', null, controller.signal)
      .then(results => {
        setPodcasts(results);
      })
      .catch(err => {
        // if err instanceof DOMException, then (hopefully) the error is from aborted request, so don't show the user that
        if (! (err instanceof DOMException)) {
          setError("Network or other error");
        }
        console.log(err);
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
          return <h1>No results</h1>;
        } else if (error) {
          return <h1>{error}</h1>;
        } else {
          return <h1>Loading...</h1>;
        }
      })()}
    </div>
  )
}
