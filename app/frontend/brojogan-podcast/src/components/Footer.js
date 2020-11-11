import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import './../css/Footer.css';
import AudioPlayer from 'react-h5-audio-player';
import 'react-h5-audio-player/lib/styles.css';
import { fetchAPI, isLoggedIn } from './../auth-functions';

// function storeTime() {
//   // get playtime, save in localstorage so can resume if refresh
// }

function Footer({ state, setState }) {
  function pingServer(progress, duration) {
    console.log("duration is '" + duration + "'");
    if (isLoggedIn()) {
      console.log("pinging " + progress + " to server episodeguid = " + state.guid + ", podcastid = " + state.podcastID);
      let uri = '/users/self/podcasts/'+state.podcastID+'/episodes/time';
      console.log("sending to " + uri);
      fetchAPI(uri, 'put', {'time': progress, 'episodeGuid': state.guid, 'duration': duration}).then(() => console.log("updated"))
    } else {
      console.log("not logged in");
    }
  }
  let setPlayed=false;
  return (
    <div id='footer-div'>
      <div id='player'>
        <table className="player-table">
          <tr>
            <td className="image-col" rowSpan="2">
              <Link to={`/podcast/${state.podcastID}`}><img src={state.thumb} className="thumbnail"></img></Link>
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
          onPause={e=>pingServer(Math.floor(Number(e.target.currentTime)), e.target.duration)}
          onListen={e=>pingServer(Math.floor(Number(e.target.currentTime)), e.target.duration)}
          onSeeked={e=>pingServer(Math.floor(Number(e.target.currentTime)), e.target.duration)}
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
