import React from 'react';
import './../css/SignUp.css';
import logo from './../images/logo.png';

function SignUp() {
  return (
    <div id='wrapper'>
      <div id='signUp-div'>
        <div id='logo-text'>
          <img 
            id="singUp-logo" 
            src={logo} 
            alt={"Logo"}
            width="150px"
            height="150px"  
          />
          <p >
            BroJogan <br /> Podcast
          </p>
        </div>
        <div id='signUp-div-2'>
          <h1>Sign Up</h1>
          <form id="signUp-form">
            <div id="username-div">
              <p id="username-text">Username</p>
              <input type="text" id="username-input"/>
            </div>
            <div>
              <p id="password-text">Password</p>
              <input type="text" id="password-input"/>
            </div>
            <div>
              <p id="password-text">Confirm Password</p>
              <input type="text" id="password-input"/>
            </div>
            <button id="signUp-btn-2" type="button">Sign Up</button>
          </form>
        </div>
      </div>
    </div>
  )
}

export default SignUp;
