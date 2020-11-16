import React, { useState, useEffect } from 'react';
import { Helmet } from 'react-helmet';
import { Link } from 'react-router-dom';
import ProgressBar from 'react-bootstrap/ProgressBar';

import { fetchAPI } from './../authFunctions';
import PagesFetch from './../components/PagesFetch';
import { getPodcastFromXML } from './../rss';

import './../css/History.css';

function History() {
  // it is up to PagesFetch to do the try catch for fetchItems()
  async function fetchItems(pgNum, signal) {
    const pageSize = 12;
    const data = await fetchAPI(`/users/self/history/${pgNum}?limit=${pageSize}`, 'get', null, signal);
    console.log("History data:", data);
    console.log(data.numPages);
    if (pgNum === 1) {
      return { items: data.history, numPages: data.numPages };
    } else {
      return { items: data.history };
    }
  }

  return (
    <div>
      <Helmet>
        <title>Brojogan Podcasts - History</title>
      </Helmet>

      <h1>Your history</h1>
      <div className="history-cards">
        <PagesFetch Item={HistoryCard} fetchItems={fetchItems} />
      </div>
    </div>
  )
}

// same as description.js, but may want to change the format
function getDate(timestamp) {
  console.log(timestamp, typeof (timestamp));
  let date = new Date(timestamp);
  // return date.toDateString(); // change to custom format
  return date.toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' }).replace(/,/g, '')/*.toUpperCase()*/;
}

// would be better to not parse the rss multiple times if there are multiple episodes of the same podcast
// but would have to communicate the state between the card and History function somehow
function HistoryCard({ details }) {
  const [state, setState] = useState();
  // let controller = new AbortController();

  useEffect(() => {

    console.log(details);
    // controller.abort();
    // controller = new AbortController();
    setState(null);

    const setCard = async () => {
      try {
        const podcast = getPodcastFromXML(details.xml);
        const episode = podcast.episodes.find(episode => episode.guid === details.episodeguid);
        setState({ podcast, episode });
      } catch (err) {
        setState({ error: "Error in retrieving details" });
      }
    }
    setCard();
  }, [details]);


  return (
    <React.Fragment>
      <div className="history-card">
        {state
          ?
          (state.error
            ? <p>{state.error}</p>
            :
            <React.Fragment>
              {/* <Link to={`/podcast/${details.pid}`}><p>{state.podcast.title}</p></Link> */}
              {/* <Link to={`/podcast/${details.pid}`}><img src={state.episode.image ? state.episode.image : state.podcast.image} alt={`${state.podcast.title}: ${state.episode.title} icon`} /></Link> */}
              <div>
                <Link to={`/podcast/${details.pid}`}>
                  <img src={state.podcast.image ? state.podcast.image : state.episode.image} alt={`${state.podcast.title}: ${state.episode.title} icon`} />
                </Link>
                <div id="test">
                  {getDate(details.listenDate * 1000)}
                </div>
              </div>
              <p id="episode-title-history">{state.episode.title}</p>
              {/* <p>Progress: {details.timestamp} (for testing)</p> */}
              {/* <p>Episode duration: {state.episode.duration}</p> */}
              {/* Some kind of progress bar based on state.timestamp.
            Though it seems like the durations in the rss feeds are sometimes wrong */}
              {state.episode.durationSeconds
                ? <ProgressBar max={state.episode.durationSeconds} now={details.timestamp /*|| 0*/} />
                : null
              }
            </React.Fragment>
          )
          :
          null}
      </div>

      {/* {state
        ?
        (state.error
          ? <p>{state.error}</p>
          :
          <div className="history-card2" style={{
            backgroundImage: `linear-gradient(#111111, transparent 30px), url(${state.podcast.image})`,
            backgroundSize: 'contain',
            backgroundRepeat: 'no-repeat',
            // color: 'dodgerblue',
            height: '300px',
            width: '150px'
          }}>
            {state.podcast.title}
          </div>
        )
        : null} */}
    </React.Fragment>
  );
}

export default History;