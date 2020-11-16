import React from 'react';
import {Link} from 'react-router-dom';
import { Helmet } from 'react-helmet';
import './../css/About.css';

function About() {
  return (
    <div>
      <Helmet>
        <title>Brojogan Podcasts - About</title>
      </Helmet>

      <h1>About Us</h1>
      <p id="about-page-p">
        Two friends meet up for coffee <br />

        ... <br /><br />

        <span id='name'>Alice:</span> We were talking and then they brought up the BroJogan Website again [sigh].<br />
        <span id='name'>Steve:</span> What's uh.. what's a BroJogan Website?<br />
        <span id='name'>Alice:</span> BroJogan.. like grabs a bunch of podcasts from different sources.<br />
        <span id='name'>Steve:</span> Huh. yeah that doesn't ring a bell. did you say 'JoeRogan'?<br />
        <span id='name'>Alice:</span> It's a great website. you don't need an account to listen, but if you do it's super personalised to what you listen to. it saves where you last left off in a podcast so you can come back to it. It provides recommendations based on what you listen to, and what you've searched. Basically it's super intuitive.<br />
        <span id='name'>Steve</span> That actually sounds really great. Where can I sign up?<br />
        <span id='name'>Alice:</span> here <Link to={`/signup`}>Sign Up</Link>. I'm super suprised you haven't heard of this yet.<br />
        <span id='name'>Steve:</span> Yeah I've no idea what BroJogan is. <br />

        ...
      </p>
    </div>
  )
}

export default About;
