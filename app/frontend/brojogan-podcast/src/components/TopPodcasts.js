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
      for (let item of items.topSubbed ) {
        console.log(JSON.stringify(item));
      }
      setTopSubbed(items.topSubbed);
    });
  }

  useEffect(() => {
    loadTopPodcasts();
  }, []);

  return (
    <div>
      <PodcastCards heading="test" podcasts={topSubbed} />
    </div>
  )
}

export default TopPodcasts;
