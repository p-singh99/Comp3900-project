import React, { useState } from 'react';
import { HowlWrapper, currentlyPlaying } from './../playing.js';
import './../css/Footer.css';

// function storeTime() {
//   // get playtime, save in localstorage so can resume if refresh
// }

function sendTime() {
  // get playtime, send to server
}

function Footer() {
  return (
    <div id='footer-div'>
      <div id='player'>
        <img src="" class="thumbnail"></img>
        <span class="material-icons" id='playpause'>play_arrow</span>
        <div class="seekbar">
          seek bar
        </div>
        <span class="material-icons" id="volume">volume_up</span>
        <span class="material-icons" id="rate">speed</span>
      </div>
    </div>
  )
}

export default Footer;
