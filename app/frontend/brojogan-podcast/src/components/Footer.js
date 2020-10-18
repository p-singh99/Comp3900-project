import React, { useState } from 'react';
import './../css/Footer.css';

function storeTime() {
  // get playtime, save in localstorage so can resume if refresh
}

function sendTime() {
  // get playtime, send to server
}

function Footer() {
  const [episode, setEpisode] = useState({src: "https://dts.podtrac.com/redirect.mp3/feeds.soundcloud.com/stream/911699122-chapo-trap-house-463-teaser-mods-will-not-save-us.mp3", podcastId: null, episodeGuid: null});

  // window.setTimeout(storeTime, 10*1000);
  // window.setTimeout(sendTime, 30*1000);

  // edit src from other components somehow
  // and only display if set
    return (
      <div id='footer-div'>
        {/* <h1>Footer</h1> */}
        <audio src={episode.src} controls preload="metadata"></audio>
      </div>
    )
}

export default Footer;
