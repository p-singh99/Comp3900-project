import React from 'react';
import ReactDOM from 'react-dom';
import {API_URL} from './../constants';
import PodcastCards from './../components/PodcastCards';
import './../css/SearchPage.css';


export default function Search(podcasts) {
        var query = window.location.search.substring(1);
        console.log(`starting query ${query}`)
        fetch(`${API_URL}/podcasts?search_query=`+query+'&offset=0&limit=50', {method: 'get'})
        .then(resp => resp.json())
    .then(podcasts => {
        const podcastList = document.getElementById("podcast-list");
        let i = 0;
        let cards = [];
        let podcastTitles = [];
        let podcastDescriptions = [];
        for (let podcast of podcasts) {
              console.log(`I is: ${i}`);
              podcastTitles.push(podcast.title);
              podcastDescriptions.push(podcast.description);
              // let newLi = document.createElement("li");
              // var text = podcast.title + " | Subscribers: " + podcast.subscribers;
              // var a = document.createElement("a");
              // a.textContent = text;
              // a.href = "/podcast/"+podcast.pid; 
              // newLi.appendChild(a);
              // podcastList.appendChild(newLi);
              
              // const actionToggleProps = {
              //   as: Button,
              //   variant: 'link',
              //   eventKey: i.toString()
              // }
              
              // const accordion = React.createElement('Accordion', {defaultActiveKey='null'}, card);
        //       const accordionToggle = React.createElement(Accordion.Toggle, {...actionToggleProps}, `Click Me ${i}`);
        //       const cardHeader = React.createElement(Card.Header, {}, accordionToggle);
        //       const cardBody = React.createElement(Card.Body, {eventKey: i.toString()}, `Hello I am the body ${i}`);
        //       const accordionCollapse = React.createElement(Accordion.Collapse, {eventKey: i.toString()}, cardBody);
        //       const card = React.createElement(Card, {}, cardHeader, accordionCollapse)
        //       cards.push(card);
        //       i++;
        }
        // const accordion = React.createElement(Accordion, {defaultActiveKey: null}, cards);
        // ReactDOM.render(
        //   [<h1>Search Results</h1>, accordion],
        //   document.getElementById('search-page-div')
        // );

        ReactDOM.render(
          <PodcastCards 
            // thumbnails={[]} 
            // podcastTitles={podcastTitles} 
            // podcastSubscribers={[]}
            // podcastDescriptions={podcastDescriptions}
            // podcastEpisodes={[[]]}
            heading={`Search Results`}
            podcasts={podcasts}
          />,
          document.getElementById('search-page-div')
        );
      });
    return (
        <div id="search-page-div">
            {/* <ul id="podcast-list">
            </ul> */}
        </div>
    )
}
