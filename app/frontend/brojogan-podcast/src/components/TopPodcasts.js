import React, {useState, useEffect} from 'react';
import { fetchAPI } from '../authFunctions';
import PodcastCards from './PodcastCards';

function TopPodcasts() {
  const [topSubbed, setTopSubbed] = useState([]);
  const [topRated, setTopRated] = useState([]);
  const [loaded, setloaded] = useState(false);

  const loadTopPodcasts = () => {

    let results = fetchAPI('/top-podcasts');
    results.then(items => {
      console.log(`Top Result is: ${JSON.stringify(items.topSubbed)}`);
      const topRatedPodcasts = [];
      const topSubscribedPodcasts = [];
      for (let item of items.topSubbed ) {
        const episodes = item.eps.map(episodeTitle => ({title: episodeTitle}));
        topSubscribedPodcasts.push({title: item.title, pid: item.id, episodes: episodes, thumbnail: item.thumbnail, subscribers: item.subs, rating: item.rating});
      }
      for (let item of items.topRated ) {
        const episodes = item.eps.map(episodeTitle => ({title: episodeTitle}));
        topRatedPodcasts.push({title: item.title, pid: item.id, episodes: episodes, thumbnail: item.thumbnail, subscribers: item.subs, rating: item.rating});
      } 
      setTopSubbed(topSubscribedPodcasts);
      setTopRated(topRatedPodcasts);
      setloaded(true);
    });
  }  

  useEffect(() => {
    loadTopPodcasts();
  }, []);

  return (
    <div>
      {!loaded ? 
        ''
      :
      <div>
        <PodcastCards heading="Most Subscribed" podcasts={topSubbed} options={{chunkedEpisodes: true}}/>
      <PodcastCards heading="Top Rated" podcasts={topRated} options={{chunkedEpisodes: true}}/>
      </div>
      }
    </div>
  )
}

export default TopPodcasts;
