import React, { useState, useEffect } from 'react';
import { Helmet } from 'react-helmet';
import PodcastCards from './../components/PodcastCards';
import { fetchAPI } from './../authFunctions';
import './../css/SearchPage.css';

export default function Search(ppodcasts) {
  const [podcasts, setPodcasts] = useState();
  const [titleQuery, setTitleQuery] = useState("");
  // const [error, setError] = useState();

  useEffect(() => {
    // setError();

    const controller = new AbortController();

    setPodcasts();
    var query = window.location.search.substring(1);
    setTitleQuery(query);
    console.log(`podcasts at start of ${query}: `, podcasts);
    console.log(`starting query ${query}`)

    // Need to send with token if logged in so backend can track searches
    fetchAPI('/podcasts?search_query=' + query + '&offset=0&limit=50', 'get', null, controller.signal)
      .then(podcasts => {
        setPodcasts(podcasts);
        // console.log(`${query}: podcasts: `, podcasts);
        // console.log(`new wls: ${window.location.search.substring(1)}`);
        // const newQuery = window.location.search.substring(1);
        // if (query === newQuery) {
        //   // component may have been rerendered with new query since that request was sent
        //   // without this, if someone does a new search before the old search request has finished,
        //   // then the old results display for a second before the new ones
        //   // would be better to use xhr and cancel the request in the cleanup instead I think
        //   // because js is single-threaded, I think it's impossible for the request to get back and be processed,
        //   // but then switch to a new component before it's displayed, and display it after?
        // }
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
      }
  }, [window.location.search]);

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
