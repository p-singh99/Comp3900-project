import React, { useState } from 'react';
import './../css/Footer.css';
import AudioPlayer from 'react-h5-audio-player';
import 'react-h5-audio-player/lib/styles.css';

// function storeTime() {
//   // get playtime, save in localstorage so can resume if refresh
// }

function sendTime() {
  // get playtime, send to server
}

function Footer({ state, setState }) {
  function pingServer(progress) {
    console.log("pinging " + progress + " to server");
  }
  return (
    <div id='footer-div'>
      <div id='player'>
        <img src={state.thumb} className="thumbnail"></img>
        <p>{state.title}</p>
        <AudioPlayer
          autoPlay
          src={state.src}
          listenInterval="30000" /*trigger onListen every 30 seconds*/
          onPause={e=>pingServer(Math.floor(Number(e.target.currentTime)))}
          onListen={e=>pingServer(Math.floor(Number(e.target.currentTime)))}
        />
      </div>
    </div>
  )
}

export default Footer;
