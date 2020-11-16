import React, { useState, useEffect } from 'react';
import { isLoggedIn, fetchAPI } from './../authFunctions';
import { getPodcastFromXML } from './../rss';
import EpisodeComponent from './EpisodeComponent';

function SubscriptionPanel() {
  const [newEpisodes, setNewEpisodes] = useState("Log In to See Subscription Panel");
  const [episodesReceived, setEpisodesReceived] = useState(false);
  const result = [];

  const loadEpisodes = () => {
    setNewEpisodes(<h4>Loading...</h4>);
    let results = fetchAPI('/users/self/subscription-panel', 'get', null);
    results.then(items => {
      console.log(`Result is: ${JSON.stringify(items)}`);
      for (let item of items) {
        console.log(`title: ${item.title}`);
        try { // getPodcastFromXML crashes sometimes so I am being liberal with try catches
          const res = getPodcastFromXML(item.xml);
          console.log(`Episode is: ${JSON.stringify(res.episodes)}`);
          console.log(`Image is: ${JSON.stringify(res.image)}`);

          result.push({
            title: item.title,
            episode: res.episodes[0],
            image: res.image,
            pid: item.pid
          }
          );

          setNewEpisodes(
            <div>
              <h4 id="episode-list-title">
                Subscription Preview Panel
              </h4>
              <div className="episode-list-container" height="50px">
                {result.map(item =>
                  <EpisodeComponent
                    podcastName={item.title}
                    episodeTitle={item.episode.title}
                    podcastImage={item.image}
                    podcastPid={item.pid}
                  />
                )}
              </div>
            </div>);
          setEpisodesReceived(true);
        } catch (err) {
          console.log("SubscriptionPanel.js:", err);
          // do nothing
        }
    }});
    results.catch(err => {
      setNewEpisodes("Error retrieving podcasts");
    })
  }

  useEffect(() => {
    if (isLoggedIn()) {
      console.log(`Logged in`);
      loadEpisodes();
    } else {
      console.log(`Not logged in`);
    }
  }, []);

  return (
    <div>
      {newEpisodes}
    </div>

  )
}

export default SubscriptionPanel;
