import React from 'react';
import './../css/SignUp.css';
import logo from './../images/logo.png';
import {API_URL} from './../constants';

function signupHandler() {
  const form = document.forms['signUp-form'];
  const username = form.elements.username.value;
  const email = form.elements.email.value;
  const password1 = form.elements.password1.value;
  const password2 = form.elements.password2.value;

  function usernameValid(username) {
    return true;
  }
  function passwordValid(password) {
    return true;
  }

  // put username validity and password requirements in the html?
  if (username && password1 && password2 && email) {
    if (! usernameValid(username)) {
      alert('Invalid username');
    } else if (! passwordValid(password1)) {
      alert('Invalid password');
    } else if (password1 !== password2) {
      alert('Passwords not matching')
    } else {
      let body = {"username": username, "email": email, "password": password1};
      fetch(`${API_URL}/users`, {method: 'post', headers: {'Content-Type': 'application/json'}, body: JSON.stringify(body)})
        .then(resp => {
          resp.json().then(data => {
            if (resp.status === 201) {
              document.cookie = data.token;
              // redirect to homepage
            } else {
              alert(data.error);
            }
          })
        })
        .catch(error => { // will this catch error from resp.json()?
          alert('Network error or something bad');
        });
    }

    // let formData = new FormData(form);
    // fetch(`{API_URL}/login`, {method: 'post', body: formData})
    //   .then(resp => {
    //     if (resp.ok) {
    //       return resp.json();
    //     } else {
    //       throw new Error('Login failed');
    //     }
    //   })
    //   .then(json => {
    //     document.cookie = `token={json.token}`;
    //     // redirect to homepage
    //   })
    //   .catch(error => {
    //     alert(error);
    //   });
  }
}


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
              <input type="text" id="username-input" name="username"/>
            </div>
            <div>
              <p id="email-text">Email</p>
              <input type="text" id="email-input" name="email"/>
            </div>
            <div>
              <p id="password-text">Password</p>
              <input type="password" id="password-input" name="password1"/>
            </div>
            <div>
              <p id="password-text">Confirm Password</p>
              <input type="password" id="password-input" name="password2"/>
            </div>
            <button id="signUp-btn-2" type="button" onClick={signupHandler}>Sign Up</button>
          </form>
        </div>
      </div>
    </div>
  )
}

export default SignUp;
