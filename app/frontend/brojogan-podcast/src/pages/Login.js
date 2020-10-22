import React from 'react';
import {Link} from 'react-router-dom';
import './../css/Login.css';
import logo from './../images/logo.png';
import {API_URL} from './../constants';
import {saveToken} from './../auth-functions';
import { useHistory } from 'react-router-dom';
import { Helmet } from 'react-helmet';

// function displayError(error) {
//   alert(error);
// }

function displayLoginError(msg) {
  document.getElementById("login-error").textContent = msg;
  document.getElementById("login-error").style.visibility = 'visible';
}

function Login() {
  // let link = '';
  const history = useHistory();

  function loginHandler(event) {
    event.preventDefault();
    // const form = document.forms['login-form'];
    const form = event.target;
    const username = form.elements.username.value;
    const password = form.elements.password.value;
    // check for maximum length? check that they don't violate some constraints?
    if (username && password) {
      let formData = new FormData(form);
      fetch(`${API_URL}/login`, {method: 'post', body: formData})
        .then(resp => {
          resp.json().then(data => {
            if (resp.status === 200) {
              saveToken(data);
              // window.location.replace("/home"); // use react redirect, should be faster?
              // window.location.href = "/home"; // this allows the back button to be used
              history.push("/");
              // return true;
            } else {
              displayLoginError("Login failed. Username or password incorrect.");
              // return false;
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
