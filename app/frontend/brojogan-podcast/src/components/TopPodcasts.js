import React, {useState, useEffect} from 'react';
import { fetchAPI } from '../authFunctions';
import PodcastCards from './PodcastCards';

function TopPodcasts() {
  const [topSubbed, setTopSubbed] = useState([]);
  const [topRated, setTopRated] = useState([]);

  const loadTopPodcasts = () => {
    // setTopSubbed('Loading Top Subbed');
    // setTopRated('Loading Top Rated');

    let results = fetchAPI('/top-podcasts');
    results.then(items => {
      console.log(`Top Result is: ${JSON.stringify(items.topSubbed)}`);
      const topRatedPodcasts = [];
      const topSubscribedPodcasts = [];
      for (let item of items.topSubbed ) {
        const episodes = item.eps.map(episodeTitle => ({title: episodeTitle}));
        topSubscribedPodcasts.push({title: item.title, pid: item.id, episodes: episodes, thumbnail: item.thumbnail, subscriber: item.subs, rating: item.rating});
      }
      for (let item of items.topRated ) {
        const episodes = item.eps.map(episodeTitle => ({title: episodeTitle}));
        topRatedPodcasts.push({title: item.title, pid: item.id, episodes: episodes, thumbnail: item.thumbnail, subscriber: item.subs, rating: item.rating});
      } 
      setTopSubbed(topSubscribedPodcasts);
      setTopRated(topRatedPodcasts);
    });
  }  

  useEffect(() => {
    loadTopPodcasts();
  }, []);

  return (
    <div>
      <PodcastCards heading="Most Subscribed" podcasts={topSubbed} options={{chunkedEpisodes: true}}/>
      <PodcastCards heading="Top Rated" podcasts={topRated} options={{chunkedEpisodes: true}}/>
    </div>
  )
}

export default TopPodcasts;
