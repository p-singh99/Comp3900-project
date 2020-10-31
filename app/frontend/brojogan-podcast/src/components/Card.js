import React, {useState, useEffect} from 'react';
import { Accordion } from 'react-bootstrap';
import Card from 'react-bootstrap/Card';
import {API_URL} from '../constants';
import { getPodcastFromXML } from './../rss';

function SubCard(props) {

  const [title, setTitle] = useState(props.title);
  const [subscribers, setSubscribers] = useState(props.subscribers);
  const [episodes, setEpisodes] = useState(props.episodes);

  // useEffect(() => {
  //   setEpisodes(props.episodes);
  //   console.log(`Episodes for ${props.pid}: ${episodes}`);
  // }, [props.episodes]);

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

  const episodeListTemp = [];
  const fetchPodcast = async () => {
    try {
      const xml = await getRSS(props.pid);
      console.log('Received RSS :' + Date.now());
      const pod = getPodcastFromXML(xml);
      episodeListTemp = pod.episodes;
      console.log('parsed XML: ' + Date.now());
      console.log(`Episodes for ${props.pid}: ${pod.episodes}`);
      console.log(`Episodes 1 for ${props.pid}: ${JSON.stringify(pod.episodes[0])}`);
    } catch (error) {
      console.log(`Error is ${error}`);
      displayError(error);
    }
  }

  useEffect(() => {
    fetchPodcast().then(
      setEpisodes(episodeListTemp)
    ); 
  })

  function displayError(msg) {
    console.log('Error loading episodes');
  }

  return (
    <Card id="card">
      <Card.Header className="card-header">
        <Accordion.Toggle className={'accordion-toggle'} as={Card.Header} variant="link" eventKey={props.pid}>
          <div className='card-header-div'>
            <a className={'search-page-link'} href = {"/podcast/" + props.pid}>
              {title}
            </a>
            <p className='subs-count'>
              Subscribers:- {subscribers}
            </p>
          </div>
        </Accordion.Toggle>
      </Card.Header>
      <Accordion.Collapse className={'accordion-collapse'} eventKey={props.pid}>
        <Card.Body className={'card-body'} eventKey={props.pid}>
          <div>
            {episodes.map((value) => 
              <div>
                <p id="episode-list-card">
                  <a id="episode-list-link" className={'search-page-link'} href = {"/podcast/" + props.pid}>
                    {value.title}
                  </a>
                </p>  
              </div>
            )}
          </div>
        </Card.Body>
      </Accordion.Collapse>
    </Card>
  )
}

export default SubCard;
