import React, { useState } from 'react';
import { HowlWrapper } from './../playing.js';
import './../css/Footer.css';

// function storeTime() {
//   // get playtime, save in localstorage so can resume if refresh
// }

function sendTime() {
  // get playtime, send to server
}

function Footer({ currentlyPlaying, setPlaying }) {
  return (
    <div id='footer-div'>
      <div id='player'>
        <img src={currentlyPlaying.thumb} className="thumbnail"></img>
        {currentlyPlaying.title}
        <button onclick={currentlyPlaying.play()}>play</button>
      </div>
    </div>
  )
}

export default Footer;
