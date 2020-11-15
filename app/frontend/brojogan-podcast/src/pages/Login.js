import React from 'react';
import { Link } from 'react-router-dom';
import { useHistory } from 'react-router-dom';
import { Helmet } from 'react-helmet';

import { API_URL } from './../constants';
import { saveToken } from './../authFunctions';

import './../css/Login.css';
import logo from './../images/logo.png';


function displayLoginError(msg) {
  document.getElementById("login-error").textContent = msg;
  document.getElementById("login-error").style.visibility = 'visible';
}

function Login() {
  const history = useHistory();

  function loginHandler(event) {
    event.preventDefault();
    const form = event.target;
    const username = form.elements.username.value;
    const password = form.elements.password.value;
    // check for maximum length? check that they don't violate some constraints?
    if (username && password) {
      let formData = new FormData(form);
      displayLoginError("...");
      fetch(`${API_URL}/login`, { method: 'post', body: formData })
        .then(resp => {
          resp.json().then(data => {
            if (resp.status === 200) {
              saveToken(data);
              history.push("/"); // this is faster than window.location.href/replace
            } else {
              displayLoginError("Login failed. Username or password incorrect.");
            }
          })
        })
        .catch(error => { // will this catch error from resp.json()?
          displayLoginError("Error"); // todo: need to stop this changing the size - set the width fixed
        });
    }
  }


  return (
    <div id="wrapper">
      <Helmet>
        <title>Brojogan Podcasts - Login</title>
      </Helmet>

      <div id='login-logo-div'>
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
        <div id="login-main-div">
          <h1>Log In</h1>
          <form id="login-form" onSubmit={loginHandler}>
            <p id="username-text">Username</p>
            <input type="text" className="login-input" id="username-input" name="username"/>
            <p id="password-text">Password</p>
            <input type="password" className="login-input" id="password-input" name="password"/>

            <p id="login-error">Login failed. Username or password incorrect.</p>
            <div id="form-btns">
              <button id="logIn-btn" type="submit">Log In</button>
              <Link to='/signup'>
                <button id="signUp-btn" type="button">Sign Up</button>
              </Link>
            </div>
          </form>
        </div>
      </div>
    </div>
  )
}

export default Login;
