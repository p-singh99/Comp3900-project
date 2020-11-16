import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { Accordion } from 'react-bootstrap';
import Card from 'react-bootstrap/Card';
import ReactStars from 'react-rating-stars-component';

import SubscribeBtn from './SubscribeBtn';
import { getPodcastFromXML } from './../rss';
import { fetchAPI } from './../authFunctions';
import './../css/Card.css';

// props: details is the object containing the details to display on this particular card
// context is options and other information given to all cards
// context.chunkedEpisodes=true means that some of the most recent episodes have been provided in details.episodes, 
// but not all of the episodes. So episode numbering when moving to the Description page should be done differently
// this frontend code has become such a mess with dependencies and weird variations everywhere
function SubCard({ details: podcast, context }) {
  const [podcastObj, setPodcastObj] = useState(); // the entire parsed XML object, for passing to the Description page
  const [episodes, setEpisodes] = useState(); // episodes for displaying in this card
  // podcast object must contain title, pid, rating, image, subscribers

  // when you do something like <Item props={state} />, when the state changes,
  // it doesn't make a new Item, it just changes the props
  // so you have to add a useEffect trigger on the props and setState to null while it's loading

  // on component load: fetch episodes if they weren't provided to the component
  useEffect(() => {

    setEpisodes(null);
    const controller = new AbortController();

    if (context && context.chunkedEpisodes) { 
      // for Recommendations - the x most recent episodes have been provided (and only their titles), no need to get and parse XML
      // but since we don't have the full XML object, we don't set podcastObj
      setEpisodes(podcast.episodes);
    } else {
      // get xml
      fetchAPI(`/podcasts/${podcast.pid}`, 'get', null, controller.signal)
        .then(data => {
          if (!data.xml) { // there is an issue with podcast's xml, the server returned xml=null
            setEpisodes(null);
            setPodcastObj({ podcast: null, subscription: data.subscription, rating: data.rating });
          } else {
            try {
              const pod = getPodcastFromXML(data.xml);
              setEpisodes(pod.episodes);
              setPodcastObj({ podcast: pod, subscription: data.subscription, rating: data.rating });
            } catch (err) {
              console.log("Card.js: getPodcastFromXML() errored:", err);
              setEpisodes(null);
              setPodcastObj({ podcast: null, subscription: data.subscription, rating: data.rating });
            }
            // change subscription to subscribed. subscribed: true/false
          }
        })
        .catch(error => {
          console.log(`Card.js fetchAPI failed: Error is ${error}`);
          displayError(error);
        })
    }

    return function cleanup() {
      controller.abort();
      // Abort request so when page changes to podB while podA is still fetching, 
      // podcastObj doesn't get to set to null and then set to podA when the response returns
      console.log("cleanup card");
    }

    // fetch for aborting 
    // https://medium.com/javascript-in-plain-english/an-absolute-guide-to-javascript-http-requests-44c685edfa51
  }, [podcast, context]);

  function displayError(msg) {
    console.log('Error loading episodes');
  }

  function getEpisodeAppendage(index, chunkedEpisodes) {
    if (chunkedEpisodes) {
      const episodeNum = index + 1;
      return `episodeRecent=${episodeNum}`;
    } else {
      const episodeNum = episodes.length - index;
      return `episode=${episodeNum}`;
    }
  }

  // Accordion is a set of cards which can be expanded one at a time by clicking on the header
  // As card is placed within other JSX, the outside of the Accordion is in the container file ie PodcastCards
  return (
    <Card className="card"> {/* has class card by default */}
      <Card.Header className="card-header">
        <Accordion.Toggle className={'accordion-toggle'} as={Card.Header} variant="link" eventKey={podcast.pid}>
          <div className='card-header-div'>
            {/* <img src={(podcastObj && podcastObj.podcast) ? podcastObj.podcast.image : 'https://i.pinimg.com/originals/92/63/04/926304843ea8e8b9bc22c52c755ec34f.gif'} alt={`${podcast.title} icon`} /> */}
            {/* Random loading gif from google, totally dodge */}
            { /* the alt is too log, wraps to next line and screws up the whole component */}
            <img src={podcast.thumbnail} alt=''/> {/* Empty alt for linter */}
            <Link className={'search-page-link'} to={{ pathname: `/podcast/${podcast.pid}`, state: { podcastObj: podcastObj } }}>
              {podcast.title}
            </Link>
            <div className="rating">
              <ReactStars
                // This is literally just a picture of a star
                count={1}
                size={24}
                activeColor="#ffd700"
                isHalf={false}
                edit={false}
                value={1}
              />
              {podcast.rating && parseFloat(podcast.rating) >= 1
                ?
                <React.Fragment>
                  <div className="current-rating-num">{podcast.rating}</div>
                  <div className="current-rating-after">/5</div>
                </React.Fragment>
                : <div className="no-ratings">No ratings</div>
              }
            </div>
            <p className='subs-count'>
              Subscribers:- {podcast.subscribers}
            </p>
            {context && context.subscribeButton && <SubscribeBtn defaultState="Unsubscribe" podcastID={podcast.pid} />}
          </div>
        </Accordion.Toggle>
      </Card.Header>
      
      <Accordion.Collapse className={'accordion-collapse'} eventKey={podcast.pid}>
        <Card.Body className={'card-body'} eventKey={podcast.pid}>
          <div>
            {/* It's extremely laggy showing all the episodes for massive (1000+ episode) podcasts*/}
            {(() => {
              if (episodes) {
                console.log("recommended JSX:", episodes.slice(0, 30));
                return (
                  episodes.slice(0, 30).map((episode, index) =>
                    <div>
                      <p id="episode-list-card">
                        <Link to={{ pathname: `/podcast/${podcast.pid}?${getEpisodeAppendage(index, context && context.chunkedEpisodes)}`, state: { podcastObj: podcastObj } }} id="episode-list-link" className="search-page-link">
                          {/* <b>{getEpisodeNumber(index) + '. '}</b> */}
                          {episode.title}
                        </Link>
                      </p>
                    </div>
                  )
                )
              } else if (podcastObj) {
                return <p>Error retrieving podcast details</p>
              } else {
                return <p>Loading episodes...</p>
              }
            })()}
          </div>
        </Card.Body>
      </Accordion.Collapse>
    </Card>
  )
}

export default SubCard;
