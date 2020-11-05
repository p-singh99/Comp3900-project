import React, {useState, useEffect} from 'react';
import ReactDOM from 'react-dom';
import { Helmet } from 'react-helmet';
import { isLoggedIn, fetchAPI } from '../auth-functions';
import PodcastCards from '../components/PodcastCards';
import {getPodcastFromXML} from '../rss';

function Recommended() {
  let [body, setBody] = useState(<h2>Loading...</h2>);
  let Podcasts = [];

  const setupPodcasts = () => {
    let result = fetchAPI('/self/recommendations', 'get');
      result.then(podcasts => {
        console.log(`Result is: ${JSON.stringify(result)}`);
        const pod = podcasts.recommendations;
        console.log("Recommended.js podcasts.recommendations");
        for (let p of pod) {
          const parsedObject = getPodcastFromXML(p);
          console.log(`Recommended Podcast is: ${JSON.stringify(parsedObject.title)}`);
          // Podcasts.push({
          //   'title': parsedObject.title , 
          //   'description': parsedObject.description,
          //   'pid': parsedObject.id,
          //   'episodes': parsedObject.episodes
          // });
          Podcasts.push(parsedObject);
        }
        console.log("Recommended end of for loop podcasts:", Podcasts)
        setBody(<PodcastCards 
          heading={'Recommendations'}
          podcasts={Podcasts}
        />);
      })     
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