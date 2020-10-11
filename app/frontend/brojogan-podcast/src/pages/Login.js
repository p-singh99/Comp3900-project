import React from 'react';
import './../css/Login.css';
import logo from './../images/logo.png';
import {API_URL} from './../constants';

function displayError(error) {
  alert(error);
}

function displayLoginError() {
  alert("Login failed");
}

function loginHandler() {
  const form = document.forms['login-form'];
  const username = form.elements.username.value;
  const password = form.elements.password.value;
  // check for maximum length? check that they don't violate some constraints?
  if (username && password) {
    // fetch('http://jsonplaceholder.typicode.com/todos/1')
    // .then(response => response.json())
    // .then(json => console.log(json));

    // let body = {"userId": 1, "title": "", "body": ""};
    // fetch('http://jsonplaceholder.typicode.com/posts', {method: 'post', headers: {'Content-Type': 'application/json'}, body: JSON.stringify(body)})
    //   .then(response => response.json())
    //   .then(json => console.log(json));

    let formData = new FormData(form);
    fetch(`${API_URL}/login`, {method: 'post', body: formData})
      .then(resp => {
        resp.json().then(data => {
          if (resp.status === 200) {
            document.cookie = `token=${data.token}`; // maybe localstorage not cookie
            // redirect to homepage
          } else {
            displayLoginError();
          }
        })
      })
      .catch(error => { // will this catch error from resp.json()?
        displayError(error);
      });

      // .then(resp => {
      //   if (resp.ok) {
      //     return resp.json();
      //   } else {
      //     throw new Error('Login failed');
      //   }
      // })
      // .then(json => {
      //   document.cookie = `token=${json.token}`; // maybe localstorage not cookie
      //   // redirect to homepage
      // })
      // .catch(error => {
      //   alert(error);
      // });
  }
}

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
        <div id="login-div-2">
          <h1>Log In</h1>
          <form id="login-form">
            <p id="username-text">Username</p>
            <input type="text" id="username-input" name="username"/>
            <p id="password-text">Password</p>
            <input type="password" id="password-input" name="password"/>
            <div id="form-btns">
              <button id="logIn-btn" type="button" onClick={loginHandler}>Log In</button>
              <button id="signUp-btn" type="button">Sign Up</button> 
            </div>
          </form>
        </div>
      </div>
    </div>
  )
}

export default Login;
