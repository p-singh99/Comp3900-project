import React from 'react';
import { Link } from 'react-router-dom';
import './../css/Footer.css';
import AudioPlayer from 'react-h5-audio-player';
import 'react-h5-audio-player/lib/styles.css';
import { fetchAPI, isLoggedIn } from './../authFunctions';
import './../css/footer.scss';

const audioPlayerStyle = {
  width: '100%',
  backgroundColor: 'rgba(255, 255, 255, 0.7)',
  border: '3px solid #6E59D6',
  borderRadius: '20px',
  paddingTop: '1px',
  paddingBottom: '1px'
};

export default class Footer extends React.Component {
  constructor(props) {
    super(props);
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

  // Send server the progress of the episode mp3
  // Also sends duration so that backend can track when play has finished
  pingServer(progress, duration) {
    if (isLoggedIn()) {
      if (isNaN(duration)) {
        // set duration as -1. handle negative durations in the backend
        console.log("duration was not a number for some reason. setting as -1 (duration is:)");
        console.log(duration)
        duration = -1;
      }
      console.log("pinging " + progress + "/" + duration + " to server episodeguid = " + this.state.guid + ", podcastid = " + this.state.podcastID);
      let uri = '/users/self/podcasts/'+this.state.podcastID+'/episodes/time';
      let body = {'time': progress, 'episodeGuid': this.state.guid, 'duration': duration};
      try {
        fetchAPI(uri, 'put', body).then(() => console.log("updated"));
      } catch(err) {
        console.log("error in playback");
        console.log(err);
      }
    }
  }

  getState() {
    return this.state;
  }

  updateState(state) {
    this.setState(state);
  }
  render() {
    let setPlayed = false;
    return (
      <div id='footer-div'>
        <div id='player'>
          <div id="podcast-playing-details">
            <Link to={`/podcast/${this.state.podcastID}`}><img src={this.state.thumb} className="thumbnail" alt=''></img></Link> {/* Linter wants empty alt */}
            <div id="podcast-playing-info">
              <p id="podcast-episode-title">
                {this.state.title}
              </p>
              <p id="podcast-playing-title">
                {this.state.podcastTitle}
              </p>
            </div>
          </div>
          <AudioPlayer
              style={audioPlayerStyle}
              customAdditionalControls={[]}
              layout="horizontal"
              autoPlay
              src={this.state.src}
              currentTime={this.state.progress}
              listenInterval="30000" /*trigger onListen every 30 seconds*/
              onPause={e=>this.pingServer(Math.floor(Number(e.target.currentTime)), e.target.duration)}
              onListen={e=>this.pingServer(Math.floor(Number(e.target.currentTime)), e.target.duration)}
              onSeeked={e=>this.pingServer(Math.floor(Number(e.target.currentTime)), e.target.duration)}
              onCanPlay={e=>{
                if (! setPlayed) {
                  setPlayed = true;
                  console.log("can play!");
                  e.target.currentTime=this.state.progress
                }
                this.pingServer(Math.floor(Number(e.target.currentTime)), e.target.duration)
                }}
            />
        </div>
      </div>
    );

  }
}


