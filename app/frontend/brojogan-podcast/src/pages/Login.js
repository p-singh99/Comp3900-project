import React from 'react';
import './../css/Login.css';
import logo from './../images/logo.png';

function Login() {
  function handler() {
    console.log('!yo');
  }
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
        <div id="login-div-2">
          <h1>Log In</h1>
          <form id="login-form">
            <p id="username-text">Username</p>
            <input type="text" id="username-input"/>
            <p id="password-text">Password</p>
            <input type="text" id="password-input"/>
            <div id="form-btns">
              <button id="logIn-btn" type="button" onClick={handler}>Log In</button>
              <button id="signUp-btn" type="button">Sign Up</button> 
            </div>
          </form>
        </div>
      </div>
    </div>
  )
}

export default Login;
