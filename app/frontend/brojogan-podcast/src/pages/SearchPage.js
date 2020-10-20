import React from 'react';
import {API_URL} from './../constants';

function Search(podcasts) {
        var query = window.location.search.substring(1);
        console.log("starting query")
        fetch(`${API_URL}/podcasts?search_query=`+query+'&offset=0&limit=50', {method: 'get'})
        .then(resp => resp.json())
    .then(podcasts => {
        const podcastList = document.getElementById("podcast-list");
        for (let podcast of podcasts) {
              let newLi = document.createElement("li");
              var text = podcast.title + " | Subscribers: " + podcast.subscribers;
              var a = document.createElement("a");
              a.textContent = text;
              a.href = "/podcast/"+podcast.pid; 
              newLi.appendChild(a);
              podcastList.appendChild(newLi);
        }
    });
    return (
        <div>
            <ul id="podcast-list">
            </ul>
        </div>
    )
}

export default Search
