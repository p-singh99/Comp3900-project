import React, { useState, useEffect } from 'react';
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

function SubCard({details: podcast}) {

  // const [title, setTitle] = useState(props.title);
  // const [subscribers, setSubscribers] = useState(props.subscribers);
  // const [episodes, setEpisodes] = useState(props.episodes);
  const [episodes, setEpisodes] = useState();
  // const [image, setImage] = useState();

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
        setEpisodes(pod.episodes);
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

  return (
    <Card id="card">
      <Card.Header className="card-header">
        <Accordion.Toggle className={'accordion-toggle'} as={Card.Header} variant="link" eventKey={podcast.pid}>
          <div className='card-header-div'>
            {/* <img src={image} style={{width: '50px', height: '50px'}} /> */}
            <a className={'search-page-link'} href={"/podcast/" + podcast.pid}>
              {podcast.title}
            </a>
            <p className='subs-count'>
              Subscribers:- {podcast.subscribers}
            </p>
          </div>
        </Accordion.Toggle>
      </Card.Header>
      <Accordion.Collapse className={'accordion-collapse'} eventKey={podcast.pid}>
        <Card.Body className={'card-body'} eventKey={podcast.pid}>
          <div>
            {episodes
              ? episodes.map((episode, index) =>
                <div>
                  <p id="episode-list-card">
                    <a id="episode-list-link" className={'search-page-link'} href={`/podcast/${podcast.pid}?episode=${episodes.length-index}`}>
                      {episode.title}
                      {/* Think should use Link or history.push() bc ahref causes restart of app I think */}
                    </a>
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
