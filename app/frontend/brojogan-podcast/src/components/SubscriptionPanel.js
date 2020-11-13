import React, {useState, useEffect} from 'react';
import {isLoggedIn, fetchAPI} from './../auth-functions';
import {getPodcastFromXML} from './../rss';
import EpisodeComponent from './EpisodeComponent';

function SubscriptionPanel() {
  const [newEpisodes, setNewEpisodes] = useState("Log In to See Subscription Panel");
  const [episodesReceived, setEpisodesReceived] = useState(false);
  const result = [];

  const loadEpisodes = () => {
    setNewEpisodes('Loading');
    let results = fetchAPI('/home', 'get', null);
    results.then(items => {
      console.log(`Result is: ${JSON.stringify(items)}`);
      for (let item of items) {
        console.log(`title: ${item.title}`);
        const res = getPodcastFromXML(item.xml);
        console.log(`Episode is: ${JSON.stringify(res.episodes)}`);
        console.log(`Image is: ${JSON.stringify(res.image)}`);

        result.push({title: item.title, 
                    episode: res.episodes[0],
                    image: res.image,
                    pid: item.pid}
                  );
      }
      const Rows = 
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
    });
  }

  useEffect (() => {
    if (isLoggedIn) {
      loadEpisodes();
    }
  }, []);

  return (
    <div>
      {newEpisodes}
    </div>

  )
}

export default SubscriptionPanel;
