import React, { useState, useEffect } from 'react';
import { Helmet } from 'react-helmet';
import { useParams } from 'react-router-dom';
import { getPodcastFromXML } from '../rss';
import { API_URL } from '../constants';
import './../css/Description.css';

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

function onTag(tag, html, options) {
  if (tag === 'p') {
    return '<br>'; // p tags screw up the div onClick, this is easier
  }
  // no return, it does default
}

// this will make sure that all rels are nofollow, but it won't add nofollow to links
function onIgnoreTagAttr(tag, name, value, isWhiteAttr) {
  if (tag === 'a' && name === 'rel') {
    return 'rel=nofollow'; // why does this work? Shouldn't I just return nofollow?
  } else if (tag === 'a' && name === 'target') {
    return 'target=_blank;'
  }
  // no return, it does default ie remove attibute
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

// function shortenDescription(description) {
//   description = unTagDescription();
//   if (description.length > 200) {
//     return description.substr(0, 197) + '...';
//   } else {
//     return description;
//   }
// }

function getDate(timestamp) {
  let date = new Date(timestamp);
  // return date.toDateString(); // change to custom format
  return date.toLocaleDateString(undefined, {year: 'numeric', month: 'short', day: 'numeric' }).replace(/,/g,'')/*.toUpperCase()*/;
}

function downloadEpisode(event) {
  alert(event.target.getAttribute('eid'));
}

function toggleDescription(event) {
  event.target.classList.toggle("collapsed");
  event.target.classList.toggle("expanded");
  // maybe want to do this fancier using js not css
}

function Description({ setPlaying }) {
  const [episodes, setEpisodes] = useState([]);
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
            {/* <p id="podcast-description" dangerouslySetInnerHTML={{ __html: sanitiseDescription(podcast.description) }}></p> */}
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
          {episodes.map(episode => {
            console.log('episode:', Date.now());

            // this is prob excessive
            let description;
            try {
              description = <p className="description collapsed" onClick={toggleDescription} dangerouslySetInnerHTML={{ __html: sanitiseDescription(episode.description) }}></p>;
            } catch {
              description = <p className="description collapsed" onClick={toggleDescription}>{unTagDescription(episode.description)}</p>;
            }

            return (
              <li className="episode">
                {/* make this flexbox or grid? */}
                <div className="head">
                  <span className="date">{getDate(episode.timestamp)}</span>
                  <span className="title">{episode.title}</span>
                </div>
                <div className="play">
                  <span className="duration">{episode.duration}</span>
                  <button className="play" eid={episode.guid} onClick={(event) => {
                    console.log("podcast is");
                    console.log(podcast);
                    console.log("episode is");
                    console.log(episode);
                    setPlaying({
                      title: episode.title,
                      podcastTitle: podcast.title,
                      src: episode.url,
                      thumb: episode.image ? episode.image : podcast.image,
                      guid: episode.guid,
                      podcastID: podcast.id,
                      progress: 0.0
                    });
                  }}>Play</button>
                  {/*<audio src={episode.url} controls preload="none"></audio>*/}
                  <button className="download" eid={episode.guid} onClick={downloadEpisode}>Download</button>
                </div>
                {/* guid won't always work because some of them will contain invalid characters I think ? */}
                {description}
                {/* <div className='description collapsed' onClick={toggleDescription} dangerouslySetInnerHTML={{ __html: sanitiseDescription(episode.description) }}> */}
                  {/* {shortenDescription(episode.description)} */}
                  {/* {unTagDescription(episode.description)} */}
                  {/* {sanitiseDescription(episode.description)} */}
                {/* </div> */}
              </li>
            )
          })}
        </ul>
      </div>
    </div>
  );
}

export default Description;
