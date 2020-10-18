import React, {useState, useEffect} from 'react';
import { Helmet } from 'react-helmet';
import {useParams} from 'react-router-dom';
import {getPodcastFromXML} from '../rss';
import {API_URL} from '../constants';
import './../css/Description.css';

function displayError(msg) {
  alert(msg);
}

/*function insertInfo(xml) {
  const podcast = getPodcastFromXML(xml);
  if (!podcast) {
    displayError("Podcast error");
    return;
  }
  
  console.log(podcast);
// insert podcast name etc. into page
  document.getElementById("podcast-name").textContent = podcast["title"];
  document.getElementById("podcast-author").textContent = podcast["author"];
  document.getElementById("podcast-description").textContent = podcast["description"];
  // with the description, they seem to be in html so we somehow need to allow some tags
  // but obv still prevent xss
  if (podcast["image"]) {
    document.getElementById("podcast-img").src = podcast["image"];
  } else {
    document.getElementById("podcast-img").remove();
  }

  const tbody = document.getElementById("episodes").getElementsByTagName("tbody")[0];
  console.log("starting episodes");
  // this takes like 2 seconds, will be much faster with virtual DOM
  // also probably only load a certain number at a time
  for (const i in podcast["episodes"]) {
    const episode = podcast["episodes"][i];
    let row = tbody.insertRow(i);
    let name = row.insertCell(0);
    name.textContent = episode["title"];

    let description = row.insertCell(1);
    description.textContent = episode["description"];

    let duration = row.insertCell(2);
    duration.textContent = episode["duration"];

    let file = row.insertCell(3);
    let audio = document.createElement("audio");
    audio.src = episode["url"];
    audio.preload = "none";
    audio.controls = true;
    file.appendChild(audio);
    // let link = document.createElement("a");
    // link.href = episode["url"];
    // link.textContent = "link";
    // link.download = "file";
    // file.appendChild(link);
  }
  console.log("finished episodes");
}*/

// CORS bypass
async function getRSS(id) {
  try {
    const resp = await fetch(`${API_URL}/podcasts/${id}`);
    const data = await resp.json();
    if (resp.status === 200) {
      // console.log(data.xml);
      return data.xml;
    } else {
      throw Error("Error in retrieving podcast");
    }
  } catch {
    throw Error("Network error");
  }
}

// There actually seems to be not much speed difference between the DOM approach and the React approach
// I can't tell which is faster

function htmlDecode(text) {
  let doc = new DOMParser().parseFromString(text, "text/html");
  return doc.documentElement.textContent;
}

function shortenDescription(description) {
  description = description.replace(/<[^>]+>/g, '');
  description = htmlDecode(description);
  if (description.length > 200) {
    return description.substr(0, 197) + '...';
  } else {
    return description;
  }
}

function getDate(timestamp) {
  let date = new Date(timestamp);
  return date.toDateString(); // change to custom format
}

function playEpisode(event) {
  alert(event.target.getAttribute('eid'));
  // put player in footer
}

function downloadEpisode(event) {
  alert(event.target.getAttribute('eid'));
}

function expandDescription(elem) {
  elem.textContent = 'long text...............................................';
}

function reduceDescription(elem) {
  elem.textContent = 'short text';
}

function toggleDescription(event) {
  alert("expand or shrink description");
  // let elem = event.target;
  // if (elem.classList.contains('shortened')) {
  //   expandDescription(elem);
  //   event.classList.remove('')
  // } else {

  // }
}

function Description(props) {
    const [episodes, setEpisodes] = useState([]);
    const [podcast, setPodcast] = useState(<h1>Loading...</h1>);
    const [podcastTitle, setPodcastTitle] = useState(""); // overlap

    // on page load:
    // send some props from search page like title, thumbnail etc., so that stuff appears faster
    const { id } = useParams();
    useEffect(() => {
      console.log('Start useeffect: ' + Date.now());
      const fetchPodcast = async () => {
          try {
            const xml = await getRSS(id);
            console.log('Received RSS :' + Date.now());
            const podcast = getPodcastFromXML(xml);
            console.log('parsed XML: ' + Date.now());
            setPodcastInfo(podcast);
            setPodcastTitle(podcast.title);
            setEpisodes(podcast.episodes);
          } catch(error) {
            displayError(error);
          }
      }
      fetchPodcast();
    }, [id]);

    function setPodcastInfo(podcast) {
      // this is stupid
      if (podcast.image) {
        setPodcast(
          <div>
            <div id="podcast-info">
              <div id="podcast-name-author">
                <h1 id="podcast-name">{podcast.title}</h1>
                <p id="podcast-author">{podcast.author}</p>
              </div>
              <img id="podcast-img" src={podcast.image} style={{height: '300px', width: '300px'}}></img>
            </div>
            <p id="podcast-description">{podcast.description}</p>
          </div>
        )
      } else {
        setPodcast(
          <div>
            <h1 id="podcast-name">{podcast.title}</h1>
            <p id="podcast-author">{podcast.author}</p>
            <p id="podcast-description">{podcast.description}</p>
          </div>
        )
      }
    }


    // useEffect(() => {
    //   getRSS(id)
    //     .then(rss => insertInfo(rss))
    //     .catch(error => displayError(error));
    // }, [id]);

  return (
    <div id="podcast">
      <Helmet>
        <title>Brojogan Podcasts - {podcastTitle}</title>
      </Helmet>
      
      {podcast}
      <div id="episodes">
        <ul>
          {episodes.map(episode => {
            console.log('episode:', Date.now());
            return (
              <li className="episode">
                <div className="head">
                  <span className="date">{getDate(episode.timestamp)}</span>
                  <span className="title">{episode.title}</span>
                </div>
                <div className="play">
                  <span className="duration">{episode.duration}</span>
                  {/* <button className="play" eid={episode.guid} onClick={playEpisode}>Play</button> */}
                  <audio src={episode.url} controls preload="none"></audio>
                  <button className="download" eid={episode.guid} onClick={downloadEpisode}>Download</button>
                </div>
                {/* guid won't work because some of them will contain invalid characters I think */}
                <div className={'description shortened'} onClick={toggleDescription}>
                  {shortenDescription(episode.description)}
                </div>
              </li>
            )
          })}
          {/* //   <tr>
          //     <td>{episode.title}</td>
          //     <td>{shortenDescription(episode.description)}</td>
          //     <td>{episode.duration}</td>
          //     <td><audio src={episode.url} controls preload="none"></audio></td>
          //   </tr>
          // )})} */}
        </ul>
      </div>

      {/* <table id="episodes">
        <thead>
          <th>Name</th>
          <th>Description</th>
          <th>Duration</th>
          <th>Audio file</th>
        </thead>
        <tbody>
          {episodes.map(episode => {
            console.log('episode:', Date.now());
            return (
            <tr>
              <td>{episode.title}</td>
              <td>{shortenDescription(episode.description)}</td>
              <td>{episode.duration}</td>
              <td><audio src={episode.url} controls preload="none"></audio></td>
            </tr>
          )})}
        </tbody>
      </table> */}
    </div>
  );
}

export default Description;
