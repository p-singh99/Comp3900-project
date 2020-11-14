import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import './../css/Footer.css';
import AudioPlayer from 'react-h5-audio-player';
import 'react-h5-audio-player/lib/styles.css';
import { fetchAPI, isLoggedIn } from './../authFunctions';

// function storeTime() {
//   // get playtime, save in localstorage so can resume if refresh
// }

// function Footer({ state, setState }) {
//   const [playing, setPlaying] = useState(state);
//   function updatState(state) {
//     setPlaying(state);
//     console.log(`State changed!!!!!!!!!`);
//   }
//   // useEffect(
//   //  () => {
//   //   console.log(`State from footer: ${JSON.stringify(state)}`);
//   //  }, [state]
//   // );
//   function pingServer(progress) {
//     if (isLoggedIn()) {
//       console.log("pinging " + progress + " to server episodeguid = " + state.guid + ", podcastid = " + state.podcastID);
//       let uri = '/users/self/podcasts/'+state.podcastID+'/episodes/time';
//       console.log("sending to " + uri);
//       fetchAPI(uri, 'put', {'time': progress, 'episodeGuid': state.guid}).then(() => console.log("updated"))
//     } else {
//       console.log("not logged in");
//     }
//   }
//   let setPlayed=false;
//   return (
//     <div id='footer-div'>
//       <div id='player'>
//         <table className="player-table">
//           <tr>
//             <td className="image-col" rowSpan="2">
//               <Link to={`/podcast/${state.podcastID}`}><img src={state.thumb} className="thumbnail"></img></Link>
//             </td>
//             <td>{state.title}</td>
//           </tr>
//           <tr>
//             <td>{state.podcastTitle}</td>
//           </tr>


//         </table>
//         <AudioPlayer
//           autoPlay
//           src={state.src}
//           currentTime={state.progress}
//           listenInterval="30000" /*trigger onListen every 30 seconds*/
//           onPause={e=>pingServer(Math.floor(Number(e.target.currentTime)))}
//           onListen={e=>pingServer(Math.floor(Number(e.target.currentTime)))}
//           onSeeked={e=>pingServer(Math.floor(Number(e.target.currentTime)))}
//           onCanPlay={e=>{
//             if (! setPlayed) {
//               setPlayed = true;
//               console.log("can play!");
//               e.target.currentTime=state.progress
//             }}}
//         />
//       </div>
//     </div>
//   )
// }

// export default Footer;

export default class Footer extends React.Component {
  constructor (props) {
    super (props);
    this.state = {
      title: "No Podcast Playing",
      podcastTitle: "",
      src: "",
      thumb: "",
      guid: "",
      podcastID: "",
      progress: 0.0
    }
    this.getState = this.getState.bind(this);
    this.updateState = this.updateState.bind(this);
    this.pingServer = this.pingServer.bind(this);
  }

  pingServer(progress) {
    if (isLoggedIn()) {
      console.log("pinging " + progress + " to server episodeguid = " + this.state.guid + ", podcastid = " + this.state.podcastID);
      let uri = '/self/podcasts/'+ this.state.podcastID+'/episodes/time';
      console.log("sending to " + uri);
      fetchAPI(uri, 'put', {'time': progress, 'episodeGuid': this.state.guid}).then(() => console.log("updated"))
    } else {
      console.log("not logged in");
    }
  }

  getState() {
    return this.state;
  }

  updateState(state) {
    this.setState(state);
  }
  render() {
    let setPlayed=false;
    return (
      <div id='footer-div'>
         <div id='player'>
           <table className="player-table">
             <tr>
               <td className="image-col" rowSpan="2">
                 <Link to={`/podcast/${this.state.podcastID}`}><img src={this.state.thumb} className="thumbnail"></img></Link>
               </td>
               <td>{this.state.title}</td>
             </tr>
             <tr>
               <td>{this.state.podcastTitle}</td>
             </tr>
           </table>
           <AudioPlayer
              autoPlay
              src={this.state.src}
              currentTime={this.state.progress}
              listenInterval="30000" /*trigger onListen every 30 seconds*/
              onPause={e=>this.pingServer(Math.floor(Number(e.target.currentTime)))}
              onListen={e=>this.pingServer(Math.floor(Number(e.target.currentTime)))}
              onSeeked={e=>this.pingServer(Math.floor(Number(e.target.currentTime)))}
              onCanPlay={e=>{
                if (! setPlayed) {
                  setPlayed = true;
                  console.log("can play!");
                  e.target.currentTime=this.state.progress
                }}}
            />
          </div>
        </div>
    );
      
  }
}


