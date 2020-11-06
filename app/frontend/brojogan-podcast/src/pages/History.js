import React, { useState, useEffect } from 'react';
import { Helmet } from 'react-helmet';
import { Link } from 'react-router-dom';
import { fetchAPI } from './../auth-functions';
import PagesFetch from './../components/PagesFetch';
import { getPodcastFromXML } from './../rss';
import { API_URL } from './../constants';
import './../css/history.css';

// this is used in multiple pages, should extract to other file
async function getRSS(id, signal) {
  let resp, data;
  try {
    resp = await fetch(`${API_URL}/podcasts/${id}`, { signal });
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

function History() {
  async function fetchItems(pgNum, signal) {
    try {
      const data = await fetchAPI(`/self/history/${pgNum}`, 'get', null, signal);
      console.log("History data:", data);
      if (pgNum === 1) {
        return { items: data.history, numPages: data.numPages };
      } else {
        return { items: data.history };
      }
    } catch (err) {
      throw err;
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

// copied from description.js, move to other file
function getDate(timestamp) {
  console.log(timestamp, typeof(timestamp));
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
        const xml = await getRSS(details.pid, controller.signal);
        const podcast = getPodcastFromXML(xml);
        const episode = podcast.episodes.find(episode => episode.guid === details.episodeguid);
        setState({ podcast, episode });
      } catch (err) {
        throw err;
      }
    }
    setCard();
  }, [details]);

  return (
    <div className="history-card">
      {state
        ?
        <React.Fragment>
          <Link to={`/podcast/${details.pid}`}><p>{state.podcast.title}</p></Link>
          <Link to={`/podcast/${details.pid}`}><img src={state.episode.image ? state.episode.image : state.podcast.image} /></Link>
          <p>{state.episode.title}</p>
          <p>Listen Date: {getDate(details.listenDate*1000)}</p>
          <p>Progress: {details.timestamp}</p>
          <p>Episode duration: {state.episode.duration}</p>
          {/* Some kind of progress bar based on state.timestamp.
          Though it seems like the durations in the rss feeds are sometimes wrong */}
        </React.Fragment>
        :
        null}
    </div>
  );
}

export default History;