import React from 'react';
import { Helmet } from 'react-helmet';
import { isLoggedIn, fetchAPI } from '../auth-functions';

function Recommended() {
  console.log("opened");
  let result = fetchAPI('/self/recommendations', 'get');
  result.then(data => console.log(`Result is: ${JSON.stringify(data)}`))

  return (
    <div>
      <Helmet>
        <title>Brojogan Podcasts - Recommended</title>
      </Helmet>
      <h1>Recommended page</h1>
    </div>
  )
}

export default Recommended;