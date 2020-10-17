import React, { useEffect } from 'react';
import {useParams} from 'react-router-dom';
import {getPodcastFromURL} from './../rss';
import {API_URL} from './../constants';

function displayError(msg) {
  alert(msg);
}

function insertInfo(podcast) {
  // insert podcast name etc. into page
  for (const episode of podcast["episodes"]) {
    // insert row into table for that episode
  }
}

async function getPodcast(id) {
  try {
    // doesn't need authorization
    const resp = await fetch(`${API_URL}/podcasts/${id}`);
    const data = await resp.json();
    if (resp.status === 200) {
      return data;
    } else {
      throw Error("Error in retrieving podcast");
    }
  } catch {
    throw Error("Network error")
  }
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
    </div>
  );
}

export default Description;