import React from 'react';
import Accordion from 'react-bootstrap/Accordion';
import SubCard from './Card';
import Pages from './Pages';

function PodcastCards(props) {

  console.log(`Props: ${props.podcasts.pid}`);

  return (
    <React.Fragment>
      <h3>
        {props.heading}
      </h3>
      <div /*id="podcast-card-accordion"*/>
        <Accordion id="podcast-card-accordion" defaultActiveKey={null}>
          <Pages Item={SubCard} itemDetails={props.podcasts} itemsPerPage={10} context={props.options} />
        {/* {props.podcasts.map((podcast) => (
        <SubCard 
          pid={String(podcast.pid)} 
          title={podcast.title} 
          subscribers={podcast.subscribers}
          episodes={podcast.episodes}
          details={podcast}
        />
      ))} */}
        </Accordion>
      </div>
    </React.Fragment>
  )
}

export default PodcastCards;
