import React, { useState, useEffect } from 'react';
import { Helmet } from 'react-helmet';
// import { useParams } from 'react-router-dom';
import ProgressBar from 'react-bootstrap/ProgressBar';
import ReactStars from 'react-rating-stars-component';
// import GetAppIcon from '@material-ui/icons/GetApp';
// import {Icon} from '@material-ui/icons';

import { getPodcastFromXML } from '../rss';
import Pages from './../components/Pages';
import './../css/Description.css';
import { isLoggedIn, fetchAPI } from '../authFunctions';
import SubscribeBtn from '../components/SubscribeBtn';

// what happens if the description is invalid html, will it break the whole page?
// eg the a tag doesn't close
// the DOMParser parsing should fail, then sanitiseDescription will fail and it won't use the description's html

// CORS bypass
async function getRSS(id) {
  return fetchAPI(`/podcasts/${id}`, 'get', null);

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


function Description(props) {
  const [episodes, setEpisodes] = useState(); // []
  const [podcast, setPodcast] = useState(null);
  const [subscribeBtn, setSubscribeBtn] = useState("Subscribe");
  const [userRating, setUserRating] = useState(undefined);
  const [rating, setRating] = useState(null);

  const setPlaying = props.setPlaying;

  // on page load:
  // const { id } = useParams(); 
  // useParams is insane and depending on whether the page is accessed by typing in the link, or by clicking on a link from somewhere else in the app,
  // it sometimes does and sometimes doesn't include query parameters in the result
  useEffect(() => {
    const id = window.location.pathname.split("/").pop();

    // get episodeNum for scrolling to specific episode
    const queryParams = new URLSearchParams(window.location.search);
    let episodeNum = parseInt(queryParams.get("episode"), 10); // NaN if episode isn't set
    let episodeNumReversed = false;
    if (!episodeNum) {
      episodeNum = parseInt(queryParams.get("episodeRecent"), 10); // NaN if episode isn't set
      episodeNumReversed = true;
    }

    function updatePodcastDetails(podcast, subscription, rating) {
      setPodcast(podcast);
      if (subscription) {
        setSubscribeBtn('Unsubscribe');
      }
      setRating(rating);
      // } else {
      //   setSubscribeBtn('Subscribe');
      // }
    }

    const fetchPodcast = async (prefetchedPodcast) => {
      try {
        let promises = [];
        if (prefetchedPodcast) {
          updatePodcastDetails((prefetchedPodcast.podcast ? prefetchedPodcast.podcast : { error: "Error loading podcast" }), prefetchedPodcast.subscription, prefetchedPodcast.rating);
        } else {
          const xmlPromise = getRSS(id);
          promises.push(xmlPromise);
        }

        // if we're logged in we'll get the listened data for this podcast
        if (isLoggedIn()) {
          let timesPromise = fetchAPI('/users/self/podcasts/' + id + '/time', 'get');
          promises.push(timesPromise);
          let ratingPromise = fetchAPI(`/users/self/ratings/${id}`);
          promises.push(ratingPromise);
        }

        // have both promises running until we can resolve both
        Promise.all(promises)
          .then(([first, second, third]) => {
            // this [xml, times] thing won't work now that both are optional
            // will fail if times is used but xml isn't, because times will get assigned as xml
            // hence the below bad code
            let times, rating;
            let podcast;
            if (prefetchedPodcast) {
              podcast = prefetchedPodcast.podcast;
              times = first;
              rating = second;
            } else {
              // we don't have the podcast object yet, need to fetch and parse xml
              const podcastDetails = first;
              if (podcastDetails.xml) {
                podcast = getPodcastFromXML(podcastDetails.xml);
                console.log("Parsed podcast:", podcast);
                try {
                  podcast = getPodcastFromXML(podcastDetails.xml);
                } catch {
                  podcast = { error: "Error loading podcast" };
                }
                // podcast.rating = podcastDetails.rating;
              } else {
                podcast = { error: "Error loading podcast" };
              }
              updatePodcastDetails(podcast, podcastDetails.subscription, podcastDetails.rating);

              times = second;
              rating = third;
            }

            // user's current time position in each episode - only for logged in users
            if (isLoggedIn()) {
              // user's current time position in each episode
              for (let time of times) {
                let episode = podcast.episodes.find(e => e.guid === time.episodeGuid);
                if (episode !== undefined) {
                  episode.progress = time.timestamp;
                  episode.listenDate = time.listenDate;
                  episode.complete = time.complete;
                } else {
                  console.error("episode with guid " + time.episodeGuid + " did not have a match in the fetched feed");
                }
              }

              // user's current rating of the podcast
              setUserRating(rating.rating);
              // user rating: undefined means not yet set
              // null means the rating has been received and the answer is that the user hasn't set one
              // number means the number is the rating
            }

            setEpisodes({ episodes: (podcast ? podcast.episodes : null), showEpisode: episodeNum, showEpisodeReversed: episodeNumReversed });
          })
          .catch(error => {
            displayError(error);
          });
      } catch (error) {
        displayError(error);
      }
    }

    let podcastObj;
    try {
      podcastObj = props.location.state.podcastObj;
    } catch {
      podcastObj = null;
    }
    // if podcastObj is provided, it must contain {podcast, subscribed, rating}
    fetchPodcast(podcastObj);

  }, [props]); // window.location

  function displayError(msg) {
    // setPodcast(<h1>{msg.toString()}</h1>);
    setPodcast({ error: msg.toString() });
  }

  async function ratingChanged(newRating) {
    const podcastID = window.location.pathname.split("/").pop();
    try {
      await fetchAPI(`/users/self/ratings/${podcastID}`, 'put', { rating: newRating });
    } catch (err) {
      // todo show some kind of error
      console.log("Description.js rating change fetchAPI error:", err);
    }
    // could cancel old requests when a new one is made but probably not woth it, it won't save any backend resources since the old request are already sent
  }

  // if numReversed, the the number is from most recent episode, in order with the episodes list
  // if not, then it is in opposite order to the episodes list
  function getEpisodeIndex(episodeNum, numReversed, episodes) {
    if (numReversed) {
      return episodeNum - 1; // NaN (falsy) if episodeReversed wasn't set
    } else if (episodeNum) {
      return episodes.length - episodeNum;
    } else {
      return null;
    }
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
        <h4>Loading...</h4>
      )
    } else if (podcast.error) {
      return (
        <h1>{podcast.error}</h1>
      )
    } else {
      return (
        <div>
          <div id="podcast-info">
            {podcast.image && <img id="podcast-img" src={podcast.image} alt="Podcast icon" />}
            <div id="podcast-name-author">
              <h1 id="podcast-name">{podcast.title}</h1>
              <h3 id="podcast-author">{podcast.author}</h3>
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
                {rating && parseFloat(rating) >= 1 // when there are no ratings for a podcast, the backend returns 0.0 as the rating. Rating can't be < 1 so we know this means no ratings.
                  ?
                  <React.Fragment>
                    <div className="current-rating-num">{rating}</div>
                    {/* <div className="current-rating-num">{podcast.rating.toFixed(1)</div> */}
                    <div className="current-rating-after">/5</div>
                  </React.Fragment>
                  : <div className="no-ratings">No ratings</div>
                }
                {userRating || userRating === null // don't render until user's rating has been retrieved, so don't have to force re-render later
                  ?
                  <ReactStars classNames="choose-rating"
                    count={5}
                    onChange={ratingChanged}
                    size={24}
                    activeColor="#ffd700"
                    isHalf={false}
                    value={userRating}
                  // key={userRating} // force re-render once the current user rating has been fetched
                  />
                  : null}
              </div>
              {isLoggedIn()
                ?
                <SubscribeBtn defaultState={subscribeBtn} podcastID={window.location.pathname.split("/").pop()} />
                : null}
                {podcast.link && <h6><a href={podcast.link} target="_blank" rel="nofollow noopener noreferrer">Podcast website</a></h6>}
              {getPodcastDescription(podcast)}
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
        <title>{podcast && podcast.title ? podcast.title : ""} - BroJogan Podcasts</title>
      </Helmet>

      {getPodcastHTML(podcast)}
      {/* It seems like JSX returned gets updated based on state that is in the JSX that is returned? */}

      <div id="episodes">
        <ul>
          {episodes && episodes.episodes && episodes.episodes.length > 0
            ? <Pages itemDetails={episodes.episodes} context={{ podcast: podcast, setPlaying: setPlaying, podcastId: window.location.pathname.split("/").pop() }} itemsPerPage={10} Item={EpisodeDescription} showItemIndex={getEpisodeIndex(episodes.showEpisode, episodes.showEpisodeReversed, episodes.episodes)} />
            : null}
        </ul>
      </div>
    </div>
  );
}

//------------------------------------------------------------------------------------
// Episode component

function getDate(timestamp) {
  let date = new Date(timestamp);
  // return date.toDateString(); // change to custom format
  return date.toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' }).replace(/,/g, '')/*.toUpperCase()*/;
}

function secondstoTime(seconds) {
  let hours = Math.floor(seconds / (60 ** 2));
  let minutes = Math.floor((seconds - hours * (60 ** 2)) / 60);
  if (hours > 0) {
    return `${hours}h ${minutes}m`
  } else {
    return `${minutes}m`;
  }
}

function EpisodeDescription({ details: episode, context: { podcast, setPlaying, podcastId }, id }) {
  const [expanded, setExpanded] = useState(false);

  useEffect(() => {
    console.log("Episode description useeffect");
    setExpanded(false);
  }, [episode, podcast, setPlaying, podcastId, id])

  function toggleDescription() {
    setExpanded(!expanded);
  }

  function getDescription(expanded) {
    // in case the sanitiser fails, don't use innerHTML
    try {
      return <div className={`description ${expanded ? "expanded" : "collapsed"}`}><p dangerouslySetInnerHTML={{ __html: sanitiseDescription(episode.description) }}></p><p><a href={episode.link} rel="nofollow noopener noreferrer" target="_blank">Episode website</a></p></div>;
    } catch {
      return <div className={`description ${expanded ? "expanded" : "collapsed"}`}><p>{unTagDescription(episode.description)}</p><p><a href={episode.link} rel="nofollow noopener noreferrer" target="_blank">Episode website</a></p></div>;
    }
  }

  // weird react bug that descriptions stay expanded after changing the page,
  // even though the entire episode div should be re-rendered with a completely new component...
  // I think it must be reacts Virtual DOM diff, it doesn't necessarily change classes I guess
  return (
    <li className={episode.complete ? "episode finished" : "episode"} id={id} onClick={toggleDescription}>
      {/* make this flexbox or grid? */}
      {episode.durationSeconds && episode.progress > 0 &&
        <div className="progress-div">
          <div>Played: {episode.complete ? "Complete" : secondstoTime(episode.progress)}</div>
          <ProgressBar max={episode.durationSeconds} now={episode.progress /*|| 0*/} />
        </div>
      }
      <div className="head">
        <span className="title">{episode.title}</span>
        <span className="date">{getDate(episode.timestamp)}</span>
      </div>
      <div className="play-div">
        <span className="duration">{episode.duration}</span>
        <button className="play" eid={episode.guid} onClick={(event) => {
          setPlaying({
            title: episode.title,
            podcastTitle: podcast.title,
            src: episode.url,
            thumb: episode.image ? episode.image : podcast.image,
            guid: episode.guid,
            podcastID: podcastId,
            listenDate: episode.listenDate ? episode.listenDate : undefined,
            progress: episode.progress ? episode.progress : 0.0
          });
        }}>Play</button>
        {/* <button className="download" eid={episode.guid} onClick={downloadEpisode}>Download</button> */}
      </div>
      {/* guid won't always work because some of them will contain invalid characters I think ? */}
      {getDescription(expanded)}
    </li>
  )
}

//---------------------------------------------------------------------
// description sanitisation code

// https://mathiasbynens.github.io/rel-noopener/
// https://css-tricks.com/use-target_blank/
// maybe use DOMPurify instead
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

  let options = {
    whiteList: {
      a: ['href'], // title
    },
    stripIgnoreTag: true,
    onTag: onTag,
  };
  description = window.filterXSS(description, options);

  // use DOMParser on description, loop through nodes, if there are any that aren't <a> or <br>, throw error and don't use innerHTML
  // and add target and rel to each <a>
  // todo: and if there is an error in parsing, throw error and don't use innerHTML
  // this is double parsing, should be able to the <a> attributes while sanitising with the right library
  const dom = (new DOMParser()).parseFromString(description, "text/html");
  for (const node of dom.querySelectorAll("body *")) {
    let nodeName = node.nodeName.toLowerCase();
    if (nodeName === "a") {
      node.setAttribute("target", "_blank");
      node.setAttribute("rel", "nofollow noopener noreferrer");
    } else if (nodeName !== "br") {
      console.log("Blocked node:", node);
      throw Error("Sanitisation failed");
    }
  }
  return dom.querySelector("body").innerHTML;
  // return description;

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
