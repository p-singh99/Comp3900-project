import React from 'react';
import './../css/Login.css';
import logo from './../images/logo.png';

function Login() {
  return (
    <div id="wrapper">
      <div id='login-div'>
        <div id="logo-text">
          <img 
            id="login-logo" 
            src={logo} 
            alt={"Logo"}
            width="150px"
            height="150px"  
          />
          <p >
            BroJogan <br /> Podcast
          </p>
        </div>
        <div id="login-form">
          <h1>Log In</h1>
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
          <div id="form-btns">
            <button id="logIn-btn" type="button">Log In</button>
            <button id="signUp-btn" type="button">Sign Up</button> 
          </div>
        </div>
      </div>
    </div>
  )
}

export default Login;
