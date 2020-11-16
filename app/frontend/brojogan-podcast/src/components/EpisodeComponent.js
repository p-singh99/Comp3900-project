import React from 'react';
import {Link} from 'react-router-dom';

import './../css/EpisodeComponent.css';

function EpisodeComponent(props) {
  return (
    <div id="episode-list">
      <img src={props.podcastImage} width={50} height={50} alt="" /> {/* Linter says to put empty string alt */}
      <div id="episode-list-text">
        <p className="episode-component-p" id="episode-title">
        <Link to={{ pathname: `/podcast/${props.podcastPid}`}}>
            {props.episodeTitle}
        </Link>
        </p>
        <p className="episode-component-p" id="podcast-title">
          <Link to={{ pathname: `/podcast/${props.podcastPid}`}}>
            {props.podcastName}
          </Link>
        </p>
      </div>
    </div>
  )
}

export default EpisodeComponent;
