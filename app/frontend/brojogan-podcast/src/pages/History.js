import React, { useState, useEffect } from 'react';
import { Helmet } from 'react-helmet';
import { Link } from 'react-router-dom';
import ProgressBar from 'react-bootstrap/ProgressBar';

import { fetchAPI } from './../authFunctions';
import PagesFetch from './../components/PagesFetch';
import { getPodcastFromXML } from './../rss';
import './../css/History.css';

// this is used in multiple pages, should extract to other file
// async function getRSS(id, signal) {
//   let resp, data;
//   try {
//     resp = await fetch(`${API_URL}/podcasts/${id}`, { signal });
//     data = await resp.json();
//   } catch {
//     throw Error("Network error");
//   }
//   if (resp.status === 200) {
//     // console.log(data.xml);
//     return data.xml;
//   } else if (resp.status === 404) {
//     throw Error("Podcast does not exist");
//   } else {
//     throw Error("Error in retrieving podcast");
//   }
// }

function History() {
  async function fetchItems(pgNum, signal) {
    const pageSize = 12;
    const data = await fetchAPI(`/self/history/${pgNum}?limit=${pageSize}`, 'get', null, signal);
    console.log("History data:", data);
    console.log(data.numPages);
    if (pgNum === 1) {
      return { items: data.history, numPages: data.numPages };
    } else {
      return { items: data.history };
    }

    // const offset = (pgNum-1)*pageSize;
    // const data = await fetchAPI(`/self/history?offset=${offset}&limit=${pageSize}`, 'get', null, signal);
    // try {

    // } catch (err) {
    //   throw err;
    // }
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

// copied from description.js, move to other file
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
  let controller = new AbortController();

  useEffect(() => {
    console.log(details);
    controller.abort();
    controller = new AbortController();
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
              <Link to={`/podcast/${details.pid}`}><p>{state.podcast.title}</p></Link>
              <Link to={`/podcast/${details.pid}`}><img src={state.episode.image ? state.episode.image : state.podcast.image} alt={`${state.podcast.title}: ${state.episode.title} icon`} /></Link>
              <p>{state.episode.title}</p>
              <p>Listen Date: {getDate(details.listenDate * 1000)}</p>
              <p>Progress: {details.timestamp} (for testing)</p>
              <p>Episode duration: {state.episode.duration}</p>
              {/* Some kind of progress bar based on state.timestamp.
            Though it seems like the durations in the rss feeds are sometimes wrong */}
              <ProgressBar max={state.episode.durationSeconds} now={details.timestamp /*|| 0*/} />
            </React.Fragment>
          )
          :
          null}
      </div>

      {state
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
        : null}
    </React.Fragment>
  );
}

export default History;