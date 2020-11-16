import React, { useState, useEffect } from 'react';
import { Helmet } from 'react-helmet';
import { isLoggedIn, fetchAPI } from '../authFunctions';
import PodcastCards from '../components/PodcastCards';

// for Recommended, the backend returns a list of podcasts
// Each podcast has title, id, image, subscribers, rating and a list of the titles of the last 30 episodes
// We put this into the format that PodcastCards expects and provide to PodcastCards,
// with an option to indicate that the episode list contains only titles of the most recent episodes, instead of all episodes
// this option affects the behaviour when clicking a link to a podcast Description page - unlike Search, it won't pass the episode list to the Description page, because it isn't complete
// However, since we provided episodes, the Card component will use that instead of refetching the xml from the backend
// this makes the Recommended page display faster but the transition from Recommended to Description page is slower
// Recommended uses PodcastCards. PodcastCards uses Pages, and passes it Item=Subcard. Pages instantiates lots of SubCards (Card.js).
function Recommended() {
  let [body, setBody] = useState(<h4>Loading...</h4>);

  const setupPodcasts = () => {
    let result = fetchAPI('/users/self/recommendations', 'get');
    result.then(data => {
      let podcasts = [];
      const recommendations = data.recommendations;
      for (let p of recommendations) {
        const episodes = p.eps.map(episodeTitle => ({title: episodeTitle}));
        console.log("mapped episodes:", episodes);

        // emulate the format of a podcast obj that Card.js expects, but with only the parts that it actually needs
        podcasts.push({title: p.title, pid: p.id, episodes: episodes, thumbnail: p.thumbnail, subscribers: p.subs, rating: p.rating});
      }
      setBody(<PodcastCards
        heading={'Recommendations'}
        podcasts={podcasts}
        options={{chunkedEpisodes: true}}
      />);
    });
    result.catch(err => {
      setBody(<h2>Error retrieving recommendations</h2>);
    });
  }

  useEffect(() => {
    if (isLoggedIn()) {
      setupPodcasts();
    } else {
      setBody("Log In to see Recommendations");
    }

  }, [])

  return (
    <React.Fragment>
      <Helmet>
        <title>Brojogan Podcasts - Recommended</title>
      </Helmet>
      <div id='recommended-div'>
        {body}
      </div>
    </React.Fragment>
  )
}

export default Recommended;