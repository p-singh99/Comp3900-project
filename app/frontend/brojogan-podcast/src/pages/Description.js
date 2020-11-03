import React, { useState, useEffect } from 'react';
import { Helmet } from 'react-helmet';
// import { useParams } from 'react-router-dom';
import { getPodcastFromXML } from '../rss';
import { API_URL } from '../constants';
import Pages from './../components/Pages';
import './../css/Description.css';
import { isLoggedIn, fetchAPI } from '../auth-functions';
// import GetAppIcon from '@material-ui/icons/GetApp';
// import {Icon} from '@material-ui/icons';

// !! what happens if the description is invalid html, will it break the whole page?
// eg the a tag doesn't close

// CORS bypass
async function getRSS(id) {
  // return fetch(`${API_URL}/podcasts/${id}`).then(resp => resp.json());
  return fetchAPI(`/podcasts/${id}`,'get',null);

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

// function Description({ setPlaying }) {
function Description(props) {
  const [episodes, setEpisodes] = useState(); // []
  const [podcast, setPodcast] = useState(null);
  // const [podcastTitle, setPodcastTitle] = useState(""); // overlaps with above
  const [subscribeBtn, setSubscribeBtn] = useState("Subscribe");
  // const [episodes, setEpisodes] = useState([]);
  // const [showEpisodeNum, setShowEpisodeNum] = useState();

  const setPlaying = props.setPlaying;

  function subscribeHandler() {
    console.log("entered into subhandler");
    var podcastID = window.location.pathname.substring(9);
    console.log(podcastID);
    let body = {};
    body.podcastid = podcastID;
    fetchAPI(`/podcasts/${podcastID}`, 'post', body)
      .then(data => {

      })
  }

  // unsubscription button
  function unSubscribeHandler() {
    console.log("entered into Unsubhandler");
    var podcastID = window.location.pathname.substring(9);
    console.log(podcastID);
    let body = {};
    body.podcastid = podcastID;
    fetchAPI(`/podcasts/${podcastID}`, 'delete', body)
      .then(data => {
        setSubscribeBtn("Subscribe");
      })
  }

  const handleClickRequest = (event) => {
    if (subscribeBtn == 'Unsubscribe') {
      /** User clicked to unsubscribe */
      unSubscribeHandler();
      setSubscribeBtn("Subscribe");
    } else {
      /** User clicked to Subscribe */
      subscribeHandler();
      setSubscribeBtn("Unsubscribe");
    }
  }

  // on page load:
  // const { id } = useParams(); 
  // useParams is insane and depending on whether the page is accessed by typing in the link, or by clicking on a link from somewhere else in the app,
  // it sometimes does and sometimes doesn't include query parameters in the result
  useEffect(() => {
    const id = window.location.pathname.split("/").pop();
    console.log('Start useeffect: ' + Date.now());
    const queryParams = new URLSearchParams(window.location.search);
    const episodeNum = queryParams.get("episode");
    console.log("episodeNum:", episodeNum);

    function updatePodcastDetails(podcast, subscription) {
      setPodcastInfo(podcast);
      console.log(`Subscribed: ${subscription}`);
      if (subscription) {
        setSubscribeBtn('Unsubscribe');
      }
    }

    const fetchPodcast = async (prefetchedPodcast) => {
      try {
        console.log("prefetched:", prefetchedPodcast);

        // TODO: need to figure out how to check for 401s etc, here.
        let promises = [];
        if (prefetchedPodcast) {
          updatePodcastDetails(prefetchedPodcast.podcast, prefetchedPodcast.subscription);
          // setPodcastInfo(prefetchedPodcast.podcast);
          // if (prefetchedPodcast.subscription) {
          //   setSubscribeBtn('Unsubscribe');
          // }
        } else {
          const xmlPromise = getRSS(id);
          // const xmlPromise = getRSS(id)//.then(data => {console.log(`Subs: ${data.subscription}`)});

          // bool isn't used, I don't know what it's for so I might have merged it to the wrong place
          // let bool;
          // xmlPromise.then(data => { bool = data.subscription });

          promises.push(xmlPromise);
        }

        // if we're logged in we'll get the listened data for this podcast
        if (isLoggedIn()) {
          let timesPromise = fetchAPI('/users/self/podcasts/' + id + '/time', 'get');
          promises.push(timesPromise);
        }

        console.log(promises);
        // have both promises running until we can resolve both
        Promise.all(promises).then(([first, second]) => {
          // this [xml, times] thing won't work now that both are optional
          // will fail if times is used but xml isn't, because times will get assigned as xml
          // hence the below bad code
          console.log("Promises all");
          let times;
          let podcast;
          if (prefetchedPodcast) {
            podcast = prefetchedPodcast.podcast;
            times = first;
          } else {
            const xml = first;
            // console.log('Received RSS :' + Date.now());
            console.log(xml);
            podcast = getPodcastFromXML(xml.xml);
            console.log(podcast);
            // console.log('parsed XML: ' + Date.now());
            // if (xml.subscription) {
            //   setSubscribeBtn('Unsubscribe');
            // }
            updatePodcastDetails(podcast, xml.subscription);

            // console.log("in start of use effect podcast is:");
            // console.log(podcast);

            // setPodcastInfo(podcast);
            times = second;
          }

          // we might not have times since its only if we're logged in
          if (times) {
            console.log("times are: ");
            console.log(times);
            for (let time of times) {
              let episode = podcast.episodes.find(e => e.guid === time.episodeGuid);
              if (episode !== undefined) {
                episode.progress = time.timestamp;
                episode.listenDate = time.listenDate;
              } else {
                console.error("episode with guid " + time.episodeGuid + " did not have a match in the fetched feed");
              }
            }
          }

          console.log("podcast:", podcast);
          setEpisodes({ episodes: podcast.episodes, showEpisode: episodeNum });
          console.log(episodes);
        });
      } catch (error) {
        displayError(error);
      }
    }

    console.log(props);
    let podcastObj;
    try {
      podcastObj = props.location.state.podcastObj;
    } catch {
      podcastObj = null;
    }
    fetchPodcast(podcastObj);

  }, [window.location]);

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
              {isLoggedIn()
                ?
                <form id="subscribe-form" onClick={() => handleClickRequest()}>
                  <div id="subscribe-btns">
                    <button id="subscribe-btn" type="button">{subscribeBtn}</button>
                  </div>
                </form>
                : null}
              {/* <p id="podcast-description" dangerouslySetInnerHTML={{ __html: sanitiseDescription(podcast.description) }}></p> */}
              {getPodcastDescription(podcast)}
              {podcast.link && <h6><a href={podcast.link} target="_blank" rel="nofollow">Podcast website</a></h6>}
            </div>
          </div>
        </div>
      )
    }
  }
  return (
    <div id="podcast">
      {}
      <Helmet>
        <title>{podcast ? podcast.title : ""} - BroJogan Podcasts</title>
      </Helmet>

      {getPodcastHTML(podcast)}

      <div id="episodes">
        <ul>
          {episodes && episodes.episodes.length > 0
            ? <Pages itemDetails={episodes.episodes} context={{ podcast: podcast, setPlaying: setPlaying }} itemsPerPage={10} Item={EpisodeDescription} showItemIndex={episodes.showEpisode} />
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

function EpisodeDescription({ details: episode, context: { podcast, setPlaying }, id }) {
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
      <div className="play-div">
        <span className="duration">{episode.duration}</span>
        {/* <button className="play" eid={episode.guid} onClick={(event) => playEpisode(event, setPlaying, episodes)}>Play</button> */}
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
