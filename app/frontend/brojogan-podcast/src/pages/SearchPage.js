import React from 'react';
import {API_URL} from './../constants';

function Search(podcasts) {
	var query = window.location.search.substring(1);
	console.log("starting query")
	fetch(`${API_URL}/podcasts?search_query=`+query+'&offset=0&limit=50', {method: 'get'})
	.then(resp => {
          resp.json().then(podcasts => {})});
    return (
        <div>
            <ul>
            </ul>
        </div>
    )
}

export default Search