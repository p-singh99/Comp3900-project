import React, { useState, useEffect } from 'react';
import { Link, useHistory } from 'react-router-dom';
import { Accordion } from 'react-bootstrap';
import Card from 'react-bootstrap/Card';
import { API_URL } from '../constants';
import { getPodcastFromXML } from './../rss';

async function getRSS(id) {
  let resp, data;
  try {
    resp = await fetch(`${API_URL}/podcasts/${id}`);
    data = await resp.json();
  } catch {
    throw Error("Network error");
  }
  if (resp.status === 200) {
    // console.log(data.xml);
    return data.xml;
  } else if (resp.status === 404) {
    throw Error("Podcast does not exist");
  } else {
    throw Error("Error in retrieving podcast");
  }
}

// async function getPodcastObj(id) {
//   const xml = await getRSS(id);
//   return getPodcastFromXML(xml);

  // I wanted to try to pass the pending promise to the Description page so it didn't have to
  // start the request from scratch
  // but it seems that isn't possible - error pass promise in props because can't clone promise

  // goes with:
  // const promise = getPodcastObj(podcast.pid);
  // setPodcastPromise(promise);
  // const pod = await Promise.resolve(promise);
// }

function SubCard({ details: podcast }) {

  // const [title, setTitle] = useState(props.title);
  // const [subscribers, setSubscribers] = useState(props.subscribers);
  // const [episodes, setEpisodes] = useState(props.episodes);
  // const [episodes, setEpisodes] = useState();
  const [podcastObj, setPodcastObj] = useState();
  // const [podcastPromise, setPodcastPromise] = useState();
  // const [image, setImage] = useState();
  // const history = useHistory();

  // useEffect(() => {
  //   setEpisodes(props.episodes);
  //   console.log(`Episodes for ${props.pid}: ${episodes}`);
  // }, [props.episodes]);

  // const episodeListTemp = [];
  // const fetchPodcast = async () => {
  //   try {
  //     const xml = await getRSS(props.pid);
  //     console.log('Received RSS :' + Date.now());
  //     const pod = getPodcastFromXML(xml);
  //     // episodeListTemp = pod.episodes;
  //     console.log('parsed XML: ' + Date.now());
  //     console.log(`Episodes for ${props.pid}: ${pod.episodes}`);
  //     console.log(`Episodes 1 for ${props.pid}: ${JSON.stringify(pod.episodes[0])}`);
  //   } catch (error) {
  //     console.log(`Error is ${error}`);
  //     displayError(error);
  //   }
  // }

  useEffect(() => {
    const setCard = async () => {
      try {
        const xml = await getRSS(podcast.pid);
        console.log('Received RSS :' + Date.now());
        const pod = getPodcastFromXML(xml);
        // episodeListTemp = pod.episodes;
        // setEpisodes(pod.episodes);
        setPodcastObj(pod);
        // setImage(pod.image);
        console.log('parsed XML: ' + Date.now());
        console.log(`Episodes for ${podcast.pid}: ${pod.episodes}`);
        // console.log(`Episodes 1 for ${podcast.pid}: ${JSON.stringify(pod.episodes[0])}`);
        console.log(podcast.image);
      } catch (error) {
        console.log(`Error is ${error}`);
        displayError(error);
      }
    };
    setCard();
  }, []);

  function displayError(msg) {
    console.log('Error loading episodes');
  }

  function getEpisodeNumber(index) {
    return podcastObj.episodes.length-index;
  }

  return (
    <Card id="card">
      <Card.Header className="card-header">
        <Accordion.Toggle className={'accordion-toggle'} as={Card.Header} variant="link" eventKey={podcast.pid}>
          <div className='card-header-div'>
            <img src={podcastObj ? podcastObj.image : 'https://i.pinimg.com/originals/92/63/04/926304843ea8e8b9bc22c52c755ec34f.gif'} style={{width: '50px', height: '50px'}} />
            {/* Random loading gif from google, totally dodge */}
            {/* change to use image returned with search results */}
            {/* <a className={'search-page-link'} href={"/podcast/" + podcast.pid}>
              {podcast.title}
            </a> */}
            <Link className={'search-page-link'} to={{ pathname: `/podcast/${podcast.pid}`, state: { podcastObj: podcastObj } }}>
              {podcast.title}
            </Link>
            <p className='subs-count'>
              Subscribers:- {podcast.subscribers}
            </p>
          </div>
        </Accordion.Toggle>
      </Card.Header>
      <Accordion.Collapse className={'accordion-collapse'} eventKey={podcast.pid}>
        <Card.Body className={'card-body'} eventKey={podcast.pid}>
          <div>
            {/* It's extremely laggy showing all the episodes for massive (1000+ episode) podcasts*/}
            {podcastObj
              ? podcastObj.episodes.slice(0, 50).map((episode, index) =>
                <div>
                  <p id="episode-list-card">
                    {/* <a id="episode-list-link" className={'search-page-link'} href={`/podcast/${podcast.pid}?episode=${episodes.length-index}`}> */}
                    {/* {episode.title} */}
                    {/* </a> */}
                    <Link to={{ pathname: `/podcast/${podcast.pid}?episode=${getEpisodeNumber(index)}`, state: { podcastObj: podcastObj } }} id="episode-list-link" className={'search-page-link'}>
                      <b>{getEpisodeNumber(index) + '. '}</b>
                      {episode.title}
                    </Link>
                  </p>
                </div>
              )
              : <p>Loading episodes...</p>
            }
          </div>
        </Card.Body>
      </Accordion.Collapse>
    </Card>
  )
}

export default SubCard;
