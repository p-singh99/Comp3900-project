import React, { useState, useEffect } from 'react';
import ReactDOM from 'react-dom';
import { Helmet } from 'react-helmet';
import { API_URL } from './../constants';
import PodcastCards from './../components/PodcastCards';
import { fetchAPI } from './../auth-functions';
import './../css/SearchPage.css';

// export default function Search(podcasts) {
//   var query = window.location.search.substring(1);
//   console.log(`starting query ${query}`)
//   fetch(`${API_URL}/podcasts?search_query=` + query + '&offset=0&limit=50', { method: 'get' })
//     .then(resp => resp.json())
//     .then(podcasts => {

//       ReactDOM.render(
//         <PodcastCards
//           heading={`Search Results`}
//           podcasts={podcasts}
//         />,
//         document.getElementById('search-page-div')
//       );
//     });
//   return (
//     <div id="search-page-div"></div>
//   )
// }
// can't use <Link> inside something rendered by ReactDOM.render()


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

      {/* <ul id="podcast-list">
            </ul> */}
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
      {/* {podcasts
        ? <PodcastCards
          heading={`Search Results`}
          podcasts={podcasts}
        />
        : null} */}
    </div>
  )
}

//   // const podcastList = document.getElementById("podcast-list");
//   // let i = 0;
//   // let cards = [];
//   // let podcastTitles = [];
//   // let podcastDescriptions = [];
//   // for (let podcast of podcasts) {
//   //   console.log(`I is: ${i}`);
//   //   podcastTitles.push(podcast.title);
//   //   podcastDescriptions.push(podcast.description);
//   // let newLi = document.createElement("li");
//   // var text = podcast.title + " | Subscribers: " + podcast.subscribers;
//   // var a = document.createElement("a");
//   // a.textContent = text;
//   // a.href = "/podcast/"+podcast.pid; 
//   // newLi.appendChild(a);
//   // podcastList.appendChild(newLi);

//   // const actionToggleProps = {
//   //   as: Button,
//   //   variant: 'link',
//   //   eventKey: i.toString()
//   // }

//   // const accordion = React.createElement('Accordion', {defaultActiveKey='null'}, card);
//   //       const accordionToggle = React.createElement(Accordion.Toggle, {...actionToggleProps}, `Click Me ${i}`);
//   //       const cardHeader = React.createElement(Card.Header, {}, accordionToggle);
//   //       const cardBody = React.createElement(Card.Body, {eventKey: i.toString()}, `Hello I am the body ${i}`);
//   //       const accordionCollapse = React.createElement(Accordion.Collapse, {eventKey: i.toString()}, cardBody);
//   //       const card = React.createElement(Card, {}, cardHeader, accordionCollapse)
//   //       cards.push(card);
//   //       i++;
//   // }
//   // const accordion = React.createElement(Accordion, {defaultActiveKey: null}, cards);
//   // ReactDOM.render(
//   //   [<h1>Search Results</h1>, accordion],
//   //   document.getElementById('search-page-div')
//   // );

//   // ReactDOM.render(
//   //   <PodcastCards 
//   //     heading={`Search Results`}
//   //     podcasts={podcasts}
//   //   />,
//   //   document.getElementById('search-page-div')
//   // );
//   // });

// }
