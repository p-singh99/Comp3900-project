import React, { useState, useEffect } from 'react';
import { Helmet } from 'react-helmet';
import { useParams } from 'react-router-dom';
import { getPodcastFromXML } from '../rss';
import { API_URL } from '../constants';
import Pages from './../components/Pages';
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
  // const [showEpisodeNum, setShowEpisodeNum] = useState();

  // on page load:
  // send some props from search page like title, thumbnail etc., so that stuff appears faster
  // since the search page uses the whole rss feed, could send that if have it
  const { id } = useParams();
  useEffect(() => {
    console.log('Start useeffect: ' + Date.now());
    const queryParams = new URLSearchParams(window.location.search);
    const episodeNum = queryParams.get("episode");
    console.log("episodeNum:", episodeNum);

    const fetchPodcast = async () => {
      try {
        const xml = await getRSS(id);
        console.log('Received RSS :' + Date.now());
        const podcast = getPodcastFromXML(xml);
        console.log('parsed XML: ' + Date.now());
        setPodcastInfo(podcast);
        setPodcastTitle(podcast.title);
        setEpisodes({episodes: podcast.episodes, showEpisode: episodeNum});
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
          {podcast.image && <img id="podcast-img" src={podcast.image} alt="Podcast icon" style={{ height: '300px', width: '300px', minWidth: '300px' }}></img>}
          <div id="podcast-name-author">
            <h1 id="podcast-name" className="podcast-heading">{podcast.title}</h1>
            <h5 id="podcast-author">{podcast.author}</h5>
            {podcastDescription}
          </div>
        </div>
      </div>
    )
  }
  return (
    <div id="podcast">
      <Helmet>
        <title>{podcastTitle} - BroJogan Podcasts</title>
      </Helmet>

      {podcast}
      <div id="episodes">
        <ul>
          {episodes
            ? <Pages itemDetails={episodes.episodes} itemsPerPage={10} Item={EpisodeDescription} showItemIndex={episodes.showEpisode}/>
            : null}
        </ul>
      </div>
    </div>
  );
}

function toggleDescription(event) {
  if (event.target.tagName.toLowerCase() !== "button") {
    const episode = event.target.closest(".episode"); // traverses element and its parents
    // console.log(episode);
    const description = episode.querySelector(".description");
    // console.log(description);
    description.classList.toggle("collapsed");
    description.classList.toggle("expanded");
    // maybe want to do this fancier using js not css
  }
}

function getDate(timestamp) {
  let date = new Date(timestamp);
  // return date.toDateString(); // change to custom format
  return date.toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' }).replace(/,/g, '')/*.toUpperCase()*/;
}

function downloadEpisode(event) {
  alert(event.target.getAttribute('eid'));
}

function EpisodeDescription({ details: episode, id }) {
  let description;
  // in case the sanitiser fails, don't use innerHTML
  try {
    description = <p className="description collapsed" dangerouslySetInnerHTML={{ __html: sanitiseDescription(episode.description) }}></p>;
  } catch {
    description = <p className="description collapsed">{unTagDescription(episode.description)}</p>;
  }

  // weird react bug that descriptions stay expanded after changing the page,
  // even though the entire episode div should be re-rendered with a completely new component...
  // I think it must be reacts Virtual DOM diff, it doesn't necessarily change classes I guess
  return (
    <li className="episode" id={id} onClick={toggleDescription}>
      {/* make this flexbox or grid? */}
      <div className="head">
        <span className="title">{episode.title}</span>
        <span className="date">{getDate(episode.timestamp)}</span>
      </div>
      <div className="play">
        <span className="duration">{episode.duration}</span>
        {/* <button className="play" eid={episode.guid} onClick={(event) => playEpisode(event, setPlaying, episodes)}>Play</button> */}
        <button>Play</button>
        <button className="download" eid={episode.guid} onClick={downloadEpisode}>Download</button>
      </div>
      {/* guid won't always work because some of them will contain invalid characters I think ? */}
      {description}
    </li>
  )
}

// maybe use DOMPurify instead, and should try to add rel="nofollow" to links
// also should set target = _blank on all links
// could also do that in js - get all links and loop through setting the attributes
// or could set base target = _blank, and then change it on the ones we control
// this doesn't really feel secure, this third party script could get bugs or be altered
// should put the script in local folder
function sanitiseDescription(description) {
  // https://www.npmjs.com/package/xss
  // https://jsxss.com/en/options.

  const onTag = (tag, html, options) => {
    if (tag === 'p') {
      return '<br>'; // p tags screw up the div onClick, this is easier
    }
    // no return, it does default
  }

  const onIgnoreTagAttr = (tag, name, value, isWhiteAttr) => {
    if (tag === 'a' && name === 'rel') {
      return 'rel=nofollow'; // why does this work? Shouldn't I just return nofollow?
    } else if (tag === 'a' && name === 'target') {
      return 'target=_blank;'
    }
    // no return, it does default ie remove attibute
  }

  let options = {
    whiteList: {
      a: ['href'], // title
      // p: [],
      // strong: []
    },
    stripIgnoreTag: true,
    onTag: onTag,
    onIgnoreTagAttr: onIgnoreTagAttr
  };
  description = window.filterXSS(description, options);
  return description;
}

// https://stackoverflow.com/questions/1912501/unescape-html-entities-in-javascript
function htmlDecode(text) {
  let doc = new DOMParser().parseFromString(text, "text/html");
  return doc.documentElement.textContent;
}

// this function is for removing tags so they don't show up in text
// it is not for security sanitisting for innerHTML
function unTagDescription(description) {
  description = description.replace(/<[^>]+>/g, ''); // remove HTML tags - could be flawed
  description = htmlDecode(description);
  return description;
}


export default Description;
