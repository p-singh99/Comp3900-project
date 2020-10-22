import React, { useState, useEffect } from 'react';
import { Helmet } from 'react-helmet';
import { useParams } from 'react-router-dom';
import { getPodcastFromXML } from '../rss';
import { API_URL } from '../constants';
import './../css/Description.css';

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

function onTag(tag, html, options) {
  if (tag === 'p') {
    return '<br>'; // p tags screw up the div onClick, this is easier
  }
  // no return, it does default
}

// this will make sure that all rels are nofollow, but it won't add nofollow to links
function onIgnoreTagAttr(tag, name, value, isWhiteAttr) {
  if (tag === 'a' && name === 'rel') {
    return 'rel=nofollow';
  }
  // no return, it does default ie remove attibute
}

// maybe use DOMPurify instead, and should try to add rel="nofollow" to links
function sanitiseDescription(description) {
  // https://www.npmjs.com/package/xss
  // https://jsxss.com/en/options.
  let options = {
    whiteList: {
      a: ['href', 'title', 'target'],
      // p: [],
      // strong: []
    },
    stripIgnoreTag: true,
    onTag: onTag,
    onIgnoreTagAttr: onIgnoreTagAttr
  };
  description = window.filterXSS(description, options);
  return description;
}

function htmlDecode(text) {
  let doc = new DOMParser().parseFromString(text, "text/html");
  return doc.documentElement.textContent;
}

function unTagDescription(description) {
  description = description.replace(/<[^>]+>/g, ''); // remove HTML tags
  // description = "&lt;script&gt;alert(1)&lt;/script&gt;"; // the <> are display as text so this seems safe
  description = htmlDecode(description);
  return description;
}

// function shortenDescription(description) {
//   description = unTagDescription();
//   if (description.length > 200) {
//     return description.substr(0, 197) + '...';
//   } else {
//     return description;
//   }
// }

function getDate(timestamp) {
  let date = new Date(timestamp);
  // return date.toDateString(); // change to custom format
  return date.toLocaleDateString(undefined, {year: 'numeric', month: 'short', day: 'numeric' }).replace(/,/g,'')/*.toUpperCase()*/;
}

function playEpisode(event, setPlaying, episodes) {
  let guid = event.target.getAttribute('eid');
  let episode = episodes.find(x => x.guid === guid);
  console.log(episode);

  console.log('playEpisode');
  // put player in footer
  setPlaying({ src: episode.url });
}

function downloadEpisode(event) {
  alert(event.target.getAttribute('eid'));
}

function toggleDescription(event) {
  event.target.classList.toggle("collapsed");
  event.target.classList.toggle("expanded");
  // maybe want to do this fancier using js not css
}

// function Description({ setPlaying }) {
function Description() {
  const [episodes, setEpisodes] = useState([]);
  const [podcast, setPodcast] = useState(<h1>Loading...</h1>);
  const [podcastTitle, setPodcastTitle] = useState(""); // overlaps with above

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
      } catch (error) {
        displayError(error);
      }
    }
    fetchPodcast();
  }, [id]);

  function displayError(msg) {
    setPodcast(<h1>{msg.toString()}</h1>);
  }

  function setPodcastInfo(podcast) {
    // css grid for this? need to add rating and subscribe button
    let podcastDescription;
    try {
      podcastDescription = <p id="podcast-description" dangerouslySetInnerHTML={{ __html: sanitiseDescription(podcast.description, true) }}></p>;
    } catch {
      podcastDescription = <p id="podcast-description">{unTagDescription(podcast.description)}</p>;
    }
    setPodcast(
      <div>
        <div id="podcast-info">
          {podcast.image && <img id="podcast-img" src={podcast.image} alt="Podcast icon" style={{ height: '300px', width: '300px' , minWidth: '300px'}}></img>}
          <div id="podcast-name-author">
            <h1 id="podcast-name">{podcast.title}</h1>
            <h3 id="podcast-author">{podcast.author}</h3>
            <p id="podcast-description" dangerouslySetInnerHTML={{ __html: sanitiseDescription(podcast.description) }}></p>
            {podcastDescription}
          </div>
        </div>
      </div>
    )
  }

  return (
    <div id="podcast">
      <Helmet>
        <title>BroJogan Podcasts - {podcastTitle}</title>
      </Helmet>

      {podcast}
      <div id="episodes">
        <ul>
          {episodes.map(episode => {
            console.log('episode:', Date.now());

            // this is prob excessive
            let description;
            try {
              description = <p className="description collapsed" onClick={toggleDescription} dangerouslySetInnerHTML={{ __html: sanitiseDescription(episode.description) }}></p>;
            } catch {
              description = <p className="description collapsed" onClick={toggleDescription}>{unTagDescription(episode.description)}</p>;
            }

            return (
              <li className="episode">
                <div className="head">
                  <span className="date">{getDate(episode.timestamp)}</span>
                  <span className="title">{episode.title}</span>
                </div>
                <div className="play">
                  <span className="duration">{episode.duration}</span>
                  {/* <button className="play" eid={episode.guid} onClick={(event) => playEpisode(event, setPlaying, episodes)}>Play</button> */}
                  <audio src={episode.url} controls preload="none"></audio>
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
          })}
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
