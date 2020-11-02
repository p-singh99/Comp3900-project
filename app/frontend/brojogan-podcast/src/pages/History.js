import React, { useState } from 'react';
import { Helmet } from 'react-helmet';
import { fetchAPI } from './../auth-functions';

function History() {
  const [history, setHistory] = useState();

  fetchAPI(`/users/self/history?offset=`, 'get')
    .then(data => {
      
    })
    .catch(err => {

    });




  return (
    <div>
      <Helmet>
        <title>Brojogan Podcasts - History</title>
      </Helmet>
      
      <h1>Your history</h1>
    </div>
  )
}

export default History;