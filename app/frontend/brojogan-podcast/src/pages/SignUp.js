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
        <div id='signUp-form'>
          <h1>Sign Up</h1>
          <div id="username-div">
            <p id="username-text">Username</p>
            <form>
              <input type="text" id="username-input"/>
            </form>
          </div>
          <div id="password-div">
            <p id="password-text">Password</p>
            <form>
              <input type="text" id="password-input"/>
            </form>
          </div>
          <div id="password-div">
            <p id="password-text">Confirm Password</p>
            <form>
              <input type="text" id="password-input"/>
            </form>
          </div>
          <button id="signUp-btn-2" type="button">Sign Up</button>
        </div>
      </div>
    </div>
  )
}

export default SignUp;
