import React, { useState, useEffect } from 'react';
import { Helmet } from 'react-helmet';
import { useParams } from 'react-router-dom';
import { getPodcastFromXML } from '../rss';
import { API_URL } from '../constants';
import Pages from './../components/Pages';
import DescriptionEpisode from './../components/DescriptionEpisode';
import { sanitiseDescription, unTagDescription } from './../descriptionSanitiser';
import './../css/Description.css';

// !! what happens if the description is invalid html, will it break the whole page?
// eg the a tag doesn't close

// CORS bypass
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

// function Description({ setPlaying }) {
function Description() {
  const [episodes, setEpisodes] = useState(); // []
  const [podcast, setPodcast] = useState(<h1>Loading...</h1>);
  const [podcastTitle, setPodcastTitle] = useState(""); // overlaps with above

  // on page load:
  // send some props from search page like title, thumbnail etc., so that stuff appears faster
  const { id } = useParams();
  useEffect(() => {
    console.log('Start useeffect: ' + Date.now());
    const fetchPodcast = async () => {
      try {
        const xml = await getRSS(id);
        console.log('Received RSS :' + Date.now());
        const podcast = getPodcastFromXML(xml);
        console.log('parsed XML: ' + Date.now());
        setPodcastInfo(podcast);
        setPodcastTitle(podcast.title);
        setEpisodes(podcast.episodes);
      } catch (error) {
        displayError(error);
      }
    }
    fetchPodcast();
  }, [id]);

  function displayError(msg) {
    setPodcast(<h1>{msg.toString()}</h1>);
  }

  function setPodcastInfo(podcast) {
    // css grid for this? need to add rating and subscribe button
    let podcastDescription;
    try {
      podcastDescription = <p id="podcast-description" dangerouslySetInnerHTML={{ __html: sanitiseDescription(podcast.description, true) }}></p>;
    } catch {
      podcastDescription = <p id="podcast-description">{unTagDescription(podcast.description)}</p>;
    }
    setPodcast(
      <div>
        <div id="podcast-info">
          {podcast.image && <img id="podcast-img" src={podcast.image} alt="Podcast icon" style={{ height: '300px', width: '300px' }}></img>}
          <div id="podcast-name-author">
            <h1 id="podcast-name">{podcast.title}</h1>
            <h3 id="podcast-author">{podcast.author}</h3>
            {podcastDescription}
          </div>
        </div>
      </div>
    )
  }

  return (
    <div id="podcast">
      <Helmet>
        <title>BroJogan Podcasts - {podcastTitle}</title>
      </Helmet>

      {podcast}
      <div id="episodes">
        <ul>
          { episodes
          ? <Pages itemDetails={episodes} itemsPerPage={10} Item={DescriptionEpisode} />
          : null }
        </ul>
      </div>
    </div>
  );
}

export default Description;
