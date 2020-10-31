import React, {useState, useEffect, useRef, useLayoutEffect} from 'react';
import Accordion from 'react-bootstrap/Accordion';
import Card from 'react-bootstrap/Card';
import Button from 'react-bootstrap/Button';
import { API_URL } from '../constants';
import { getPodcastFromXML } from './../rss';
import ReactDOM from 'react-dom';
// import json from'parse-json';


function PodcastCards(props) {
  
  const [episodeList, setEpisdodeList] = useState([]);
  const [items, setItems] = useState([]);
  const first = useRef(true);

  let episodeListTemp = [];

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

  const fetchPodcast = async () => {
    for (let podcast of props.podcasts) {
      try {
        const xml = await getRSS(podcast.pid);
        console.log('Received RSS :' + Date.now());
        const pod = getPodcastFromXML(xml);
        console.log('parsed XML: ' + Date.now());
        episodeListTemp[podcast.pid] = pod.episodes;
        console.log(`Episodes for ${podcast.pid}: ${pod.episodes}`);
        console.log(`Episodes 1 for ${podcast.pid}: ${JSON.stringify(pod.episodes[0])}`);
      } catch (error) {
        console.log(`Error is ${error}`);
        displayError(error);
      }
    }
  }

  function displayError(msg) {
    console.log('Error loading episodes');
  }

  fetchPodcast().then(() => {
    ReactDOM.render(
      renderItems(),
      document.getElementById('podcast-card-accordion')
    );
  });

  const renderItems = () => {
    return <Accordion id="podcast-card-accordion" defaultActiveKey = {null}>
      {props.podcasts.map((podcast) => (
      <Card id='card'>
          <Card.Header className='card-header'>
            <Accordion.Toggle className={'accordion-toggle'} as={Card.Header} variant="link" eventKey={podcast.title}>
              <div className='card-header-div'>
                <a className={'search-page-link'} href = {"/podcast/" + podcast.pid}>
                  {podcast.title}
                </a>
                <p className='subs-count'>
                  Subscribers:- {podcast.subscribers}
                </p>
              </div>
            </Accordion.Toggle>
          </Card.Header>
          <Accordion.Collapse className={'accordion-collapse'} eventKey={podcast.title}>
            <Card.Body className={'card-body'} eventKey={podcast.title}>
              <div>
                  {episodeListTemp[podcast.pid] != undefined ? episodeListTemp[podcast.pid].map((value) => 
                    <div>
                      <p id="episode-list-card">
                      <a id="episode-list-link" className={'search-page-link'} href = {"/podcast/" + podcast.pid}>
                        {value.title}
                      </a>
                      </p>  
                    </div>
                  ): "Error loading episodes for this podcast"}
              </div>
            </Card.Body>
          </Accordion.Collapse>
        </Card>
      ))}
      </Accordion>
  };  

  return (
    <React.Fragment>
        <h3>
          {props.heading}
        </h3>
      <div id="podcast-card-accordion">
        <p>
          Loading ...
        </p>
      </div>
    </React.Fragment>
  )

}

export default PodcastCards;
