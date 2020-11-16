import React from 'react';
import Accordion from 'react-bootstrap/Accordion';
import SubCard from './Card';
import Pages from './Pages';

// Uses Pages
// props: 
//  podcasts is a list of details, one element is one podcast and one card
//  options is given to SubCard as context
//  heading is a heading for the page
function PodcastCards(props) {

  // console.log(`Props: ${props.podcasts.pid}`);

  return (
    <React.Fragment>
      <h4>
        {props.heading}
      </h4>
      <div /*id="podcast-card-accordion"*/>
        <Accordion id="podcast-card-accordion" defaultActiveKey={null}>
          {/* {props.usePages == true 
            ?  */}
              <Pages Item={SubCard} itemDetails={props.podcasts} itemsPerPage={10} context={props.options} />
            {/* :  */}
              {/* <SubCard 
                pid={String(podcast.pid)} 
                title={podcast.title} 
                subscribers={podcast.subscribers}
                episodes={podcast.episodes}
                details={podcast}
              /> */}
          {/* } */}
        {/* {props.podcasts.map((podcast) => (
        
      ))} */}
        </Accordion>
      </div>
    </React.Fragment>
  )
}

export default PodcastCards;
