import React, {useEffect} from 'react';
import Accordion from 'react-bootstrap/Accordion';
import ReactDOM from 'react-dom';
import SubCard from './Card';

function PodcastCards(props) {

  return (
    <React.Fragment>
      <h3>
        {props.heading}
      </h3>
      <div id="podcast-card-accordion">
        <Accordion id="podcast-card-accordion" defaultActiveKey={null}>
        {props.podcasts.map((podcast) => (
        <SubCard 
          pid={String(podcast.pid)} 
          title={podcast.title} 
          subscribers={podcast.subscribers}
          episodes={[]}
        />
      ))}
        </Accordion>
      </div>
    </React.Fragment>
  )

  // const renderItems = () => {
  //   return <Accordion id="podcast-card-accordion" defaultActiveKey = {null}>
  //     {props.podcasts.map((podcast) => (
  //       <SubCard 
  //         pid={String(podcast.pid)} 
  //         title={podcast.title} 
  //         subscribers={podcast.subscribers}
  //         episodes={[]}
  //       />
  //     ))}
  //   </Accordion>
  // }

  // useEffect(() => {
  //   ReactDOM.render(
  //     renderItems(),
  //     document.getElementById("podcast-card-accordion")
  //   );
  // });

  // return (
  //   <React.Fragment>
  //     <h3>
  //       {props.heading}
  //     </h3>
  //     <div id="podcast-card-accordion">
  //       <p>
  //         Loading ...
  //       </p>
  //     </div>
  //   </React.Fragment>
  // )
}

export default PodcastCards;
