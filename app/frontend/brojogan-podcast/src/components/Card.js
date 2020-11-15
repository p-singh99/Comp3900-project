import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { Accordion } from 'react-bootstrap';
import Card from 'react-bootstrap/Card';
import ReactStars from 'react-rating-stars-component';

import SubscribeBtn from './SubscribeBtn';
import { getPodcastFromXML } from './../rss';
import { fetchAPI } from './../authFunctions';
import './../css/Card.css';


function SubCard({ details: podcast, context }) {
  const [podcastObj, setPodcastObj] = useState();
  console.log("Podcast:", podcast);

  // note to self: when you do something like <Item props={state} />, when the state changes,
  // it doesn't make a new Item, it just changes the props
  // so you have to add a useEffect trigger on the props and setState to null while it's loading
  useEffect(() => {
    setPodcastObj(null);

    // todo: so subscription endpoint returns title, author, description etc, we should use that?

    const controller = new AbortController();
    const setCard = async () => {
      try {
        console.log(context && context.subscribeButton);
        // need to make this a cancellable promise so when page changes to podB while podA is still fetching, 
        // podcastObj doesn't get to set to null and then set to podA when the response returns
        const data = await fetchAPI(`/podcasts/${podcast.pid}`, 'get', null, controller.signal);
        console.log(data);
        if (!data.xml) {
          setPodcastObj({ podcast: null, subscription: data.subscription, rating: data.rating});
        } else {
          const pod = getPodcastFromXML(data.xml);
          setPodcastObj({ podcast: pod, subscription: data.subscription, rating: data.rating });
          console.log(`Episodes for ${podcast.pid}`);
        }
      } catch (error) {
        console.log(`Error is ${error}`);
        displayError(error);
      }
    };
    if (!podcast.episodes || podcast.episodes.length === 0) {
      setCard();
    } else { // the xml has already been parsed and episodes are available
      console.log("podcast:", podcast);
      setPodcastObj({ podcast: podcast });
    }

    return function cleanup() {
      controller.abort();
      console.log("cleanup card");
    }

    // fetch for aborting 
    // https://medium.com/javascript-in-plain-english/an-absolute-guide-to-javascript-http-requests-44c685edfa51
  }, [podcast, context]);

  function displayError(msg) {
    console.log('Error loading episodes');
  }

  function getEpisodeNumber(index) {
    return podcastObj.podcast.episodes.length - index;
  }

  return (
    <Card /*id="card"*/> {/* multiple elements with same id. has class card by default */}
      <Card.Header className="card-header">
        <Accordion.Toggle className={'accordion-toggle'} as={Card.Header} variant="link" eventKey={podcast.pid}>
          <div className='card-header-div'>
            <img src={(podcastObj && podcastObj.podcast) ? podcastObj.podcast.image : 'https://i.pinimg.com/originals/92/63/04/926304843ea8e8b9bc22c52c755ec34f.gif'} alt={`${podcast.title} icon`} />
            {/* Random loading gif from google, totally dodge */}
            {/* change to use image returned with search results */}
            {/* <a className={'search-page-link'} href={"/podcast/" + podcast.pid}>
              {podcast.title}
            </a> */}
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
              {podcast.rating
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
            {/* {context && context.subscribeButton && <button className="subscribe-btn" onClick={(event) => handleClickRequest(event, podcast.pid)}>{subscribeBtn}</button>} */}
            {context && context.subscribeButton && <SubscribeBtn defaultState="Unsubscribe" podcastID={podcast.pid} />}
          </div>
        </Accordion.Toggle>
      </Card.Header>
      <Accordion.Collapse className={'accordion-collapse'} eventKey={podcast.pid}>
        <Card.Body className={'card-body'} eventKey={podcast.pid}>
          <div>
            {/* It's extremely laggy showing all the episodes for massive (1000+ episode) podcasts*/}
            {(() => {
              if (podcastObj && podcastObj.podcast) {
                console.log("recommended JSX:", podcastObj.podcast.episodes.slice(0, 50));
                return (
                  podcastObj.podcast.episodes.slice(0, 30).map((episode, index) =>
                    <div>
                      <p id="episode-list-card">
                        {/* <a id="episode-list-link" className={'search-page-link'} href={`/podcast/${podcast.pid}?episode=${episodes.length-index}`}> */}
                        {/* {episode.title} */}
                        {/* </a> */}
                        <Link to={{ pathname: `/podcast/${podcast.pid}?episode=${getEpisodeNumber(index)}`, state: { podcastObj: podcastObj } }} id="episode-list-link" className={'search-page-link'}>
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
