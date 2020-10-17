import React, { useEffect } from 'react';
import {useParams} from 'react-router-dom';
import {getPodcastFromURL} from './../rss';
import {API_URL} from './../constants';

function displayError(msg) {
  // alert(msg);
  const elem = document.getElementById("description-error");
  elem.textContent = msg;
}

function insertInfo(podcast) {
  // insert podcast name etc. into page
  for (const episode of podcast["episodes"]) {
    // insert row into table for that episode
  }
}

async function getPodcast(id) {
  // try {
  // doesn't need authorization
  let resp;
  try {
    resp = await fetch(`${API_URL}/podcasts/${id}`);
  } catch {
    throw Error("Network error");
  }
  if (resp.status === 200) {
    return await resp.json();
  } else if (resp.status == 404) {
    throw Error("Podcast not found");
  } else {
    throw Error("Error in retrieving podcast");
  }
  // } catch (err) {
  //   throw Error(err)
  // }
}

function Description(props) {
  // on page load:
  const { id } = useParams();
  useEffect(() => {
    getPodcast(id)
      .then(podcast => insertInfo(podcast))
      .catch(error => displayError(error));
  }, []);

  return (
    <div>
      <h1>Welcome to the Decription page for podcast {props.name}</h1>
      {id}
      <p id="description-error"></p>
    </div>
  );
}

export default Description;