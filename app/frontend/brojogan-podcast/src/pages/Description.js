import React, {useEffect} from 'react';
import {useParams} from 'react-router-dom';
import {getPodcastFromXML} from '../rss';
import {API_URL} from '../constants';

function displayError(msg) {
  alert(msg);
}

function insertInfo(xml) {
  getPodcastFromXML(xml)
    .then(podcast => {
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
        // // link.target = "_blank";
        // link.textContent = "link";
        // audio.appendChild(link);
      }
      console.log("finished episodes");
  })
    .catch(error => displayError(error));
}

// CORS bypass
async function getRSS(id) {
  try {
    const resp = await fetch(`${API_URL}/podcasts/${id}`);
    const data = await resp.json();
    if (resp.status === 200) {
      console.log(data.xml);
      return data.xml;
    } else {
      throw Error("Error in retrieving podcast");
    }
  } catch {
    throw Error("Network error");
  }
}

function Description(props) {
    // on page load:
    const { id } = useParams();
    useEffect(() => {
      getRSS(id)
        .then(rss => insertInfo(rss))
        .catch(error => displayError(error));
    // eslint-disable-next-line react-hooks/exhaustive-deps
    }, []);

  return (
    <div>
      {/* <h1>Welcome to the Decription page for podcast {props.name}</h1> */}
      {/* This is a proof of concept, needs proper react stuff */}
      <h1 id="podcast-name">Loading...</h1>
      <p id="podcast-author"></p>
      <img id="podcast-img" style={{height: '300px', width: '300px'}}></img>
      <p id="podcast-description"></p>
      <table id="episodes">
        <thead>
          <th>Name</th>
          <th>Description</th>
          <th>Duration</th>
          <th>Audio file</th>
        </thead>
        <tbody></tbody>
      </table>
    </div>
  );
}

export default Description;