import React, { useState } from 'react';
import './../css/Footer.css';
import AudioPlayer from 'react-h5-audio-player';
import 'react-h5-audio-player/lib/styles.css';
import { fetchAPI } from './../auth-functions';

// function storeTime() {
//   // get playtime, save in localstorage so can resume if refresh
// }

function sendTime() {
  // get playtime, send to server
}

function Footer({ state, setState }) {
  function pingServer(progress) {
    console.log("pinging " + progress + " to server episodeguid = " + state.guid + ", podcastid = " + state.podcastID);
    let uri = '/users/self/podcasts/'+state.podcastID+'/episodes/time';
    console.log("sending to " + uri);
    fetchAPI(uri, 'put', {'time': progress, 'episodeGuid': state.guid}).then(() => console.log("updated"))
  }
  let setPlayed=false;
  return (
    <div id='footer-div'>
      <div id='player'>
        <table className="player-table">
          <tr>
            <td className="image-col" rowSpan="2">
              <img src={state.thumb} className="thumbnail"></img>
            </td>
            <td>{state.title}</td>
          </tr>
          <tr>
            <td>{state.podcastTitle}</td>
          </tr>


        </table>
        <AudioPlayer
          autoPlay
          src={state.src}
          currentTime={state.progress}
          listenInterval="30000" /*trigger onListen every 30 seconds*/
          onPause={e=>pingServer(Math.floor(Number(e.target.currentTime)))}
          onListen={e=>pingServer(Math.floor(Number(e.target.currentTime)))}
          onSeeked={e=>pingServer(Math.floor(Number(e.target.currentTime)))}
          onCanPlay={e=>{
            if (! setPlayed) {
              setPlayed = true;
              console.log("can play!");
              e.target.currentTime=state.progress
            }}}
        />
      </div>
    </div>
  )
}

export default Footer;
