import React, { useState, useEffect } from 'react';
import { Helmet } from 'react-helmet';
import { useParams } from 'react-router-dom';
import { getPodcastFromXML } from '../rss';
import { API_URL } from '../constants';
import AudioPlayer from 'react-h5-audio-player';
import './../css/Description.css';
import { isLoggedIn, fetchAPI } from '../auth-functions';

// !! what happens if the description is invalid html, will it break the whole page?
// eg the a tag doesn't close

// CORS bypass
async function getRSS(id) {
  return fetch(`${API_URL}/podcasts/${id}`).then(resp => resp.json());
  /*
  let resp, data;
  try {
    resp = 
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
  }*/
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
  const [podcast, setPodcast] = useState(null);
  const [podcastTitle, setPodcastTitle] = useState(""); // overlaps with above

  // on page load:
  // send some props from search page like title, thumbnail etc., so that stuff appears faster
  const { id } = useParams();
  useEffect(() => {
    console.log('Start useeffect: ' + Date.now());
    const fetchPodcast = async () => {
      try {
        // TODO: need to figure out how to check for 401s etc, here.
        const xmlPromise = getRSS(id);
        let promises = [xmlPromise];

        // if we're logged in we'll get the listened data for this podcast
        if (isLoggedIn()) {
          let timesPromise = fetchAPI('/users/self/podcasts/'+id+'/time', 'get');
          promises.push(timesPromise);
        }

        // have both promises running until we can resolve both
        Promise.all(promises).then(([xml, times]) => {
          console.log('Received RSS :' + Date.now());
          console.log(xml);
          const podcast = getPodcastFromXML(xml.xml);
          console.log('parsed XML: ' + Date.now());
          
          // we might not have times since its only if we're logged in
          if (times) {
            console.log("times are: ");
            console.log(times);
            for (let time of times) {
              let episode = podcast.episodes.find(e => e.guid===time.episodeGuid);
              if (episode !== undefined) {
                episode.progress = time.timestamp;
                episode.listenDate = time.listenDate;
              } else {
                console.error("episode with guid " + time.episodeGuid + " did not have a match in the fetched feed");
              }
            }

            setPodcastInfo(podcast);
            setPodcastTitle(podcast.title);
            setEpisodes(podcast.episodes);
          }
        });
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
    
    setPodcast(podcast)
  }

  function getPodcastDescription(podcast) {
    let podcastDescription;
    try {
      podcastDescription = <p id="podcast-description" dangerouslySetInnerHTML={{ __html: sanitiseDescription(podcast.description, true) }}></p>;
    } catch {
      podcastDescription = <p id="podcast-description">{unTagDescription(podcast.description)}</p>;
    }

    return podcastDescription;
  }

  function getPodcastHTML(podcast) {
    if (podcast === null) {
      return (
        <h1>Loading...</h1>
      )
    } else {
      return (
        <div>
          <div id="podcast-info">
            {podcast.image && <img id="podcast-img" src={podcast.image} alt="Podcast icon" style={{ height: '300px', width: '300px' }}></img>}
            <div id="podcast-name-author">
              <h1 id="podcast-name">{podcast.title}</h1>
              <h3 id="podcast-author">{podcast.author}</h3>
              {/* <p id="podcast-description" dangerouslySetInnerHTML={{ __html: sanitiseDescription(podcast.description) }}></p> */}
              {getPodcastDescription(podcast)}
            </div>

          </div>
        </div>
      )
    }
  }
  let e = [];
  e.push(episodes[0]);
  return (
    <div id="podcast">
      {}
      <Helmet>
        <title>BroJogan Podcasts - {podcastTitle}</title>
      </Helmet>

      {getPodcastHTML(podcast)}      
      
      
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
                  <span className="title">{episode.title}</span>
                  <span className="date">{getDate(episode.timestamp)}</span>
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
                      podcastID: id,
                      listenDate: episode.listenDate ? episode.listenDate : undefined,
                      progress: episode.progress ? episode.progress : 0.0
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
