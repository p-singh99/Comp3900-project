import React, { useState, useEffect } from 'react';
import { sanitiseDescription, unTagDescription } from './../descriptionSanitiser';
import './../css/Description.css';

function toggleDescription(event) {
  event.target.classList.toggle("collapsed");
  event.target.classList.toggle("expanded");
  // maybe want to do this fancier using js not css
}

function getDate(timestamp) {
  let date = new Date(timestamp);
  // return date.toDateString(); // change to custom format
  return date.toLocaleDateString(undefined, {year: 'numeric', month: 'short', day: 'numeric' }).replace(/,/g,'')/*.toUpperCase()*/;
}

function downloadEpisode(event) {
  alert(event.target.getAttribute('eid'));
}

function DescriptionEpisode({ details: episode }) {
  // this is prob excessive
  let description;
  try {
    description = <p className="description collapsed" onClick={toggleDescription} dangerouslySetInnerHTML={{ __html: sanitiseDescription(episode.description) }}></p>;
  } catch {
    description = <p className="description collapsed" onClick={toggleDescription}>{unTagDescription(episode.description)}</p>;
  }

  return (
    <li className="episode">
      {/* make this flexbox or grid? */}
      <div className="head">
        <span className="date">{getDate(episode.timestamp)}</span>
        <span className="title">{episode.title}</span>
      </div>
      <div className="play">
        <span className="duration">{episode.duration}</span>
        {/* <button className="play" eid={episode.guid} onClick={(event) => playEpisode(event, setPlaying, episodes)}>Play</button> */}
        {/* <audio src={episode.url} controls preload="none"></audio> */}
        <button>Play</button>
        <button className="download" eid={episode.guid} onClick={downloadEpisode}>Download</button>
      </div>
      {/* guid won't always work because some of them will contain invalid characters I think ? */}
      {description}
      {/* <div className='description collapsed' onClick={toggleDescription} dangerouslySetInnerHTML={{ __html: sanitiseDescription(episode.description) }}> */}
      {/* {shortenDescription(episode.description)} */}
      {/* {unTagDescription(episode.description)} */}
      {/* {sanitiseDescription(episode.description)} */}
      {/* </div> */}
    </li>
  )
}

export default DescriptionEpisode;
