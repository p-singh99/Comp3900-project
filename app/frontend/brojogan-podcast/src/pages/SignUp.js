import React from 'react';
import './../css/SignUp.css';
import logo from './../images/logo.png';
import { API_URL } from './../constants';

// General error eg network error
function displayError(error) {
  alert(error);
}

// sign up fail eg email already exists
function displaySignupError(error) {
  alert(error);
}

// change
function displayPasswordError(msg) {
  document.getElementsByClassName("password-info")[0].textContent = msg;
}

function usernameValid(username) {
  return true;
}
function passwordValid(password) {
  return true;
}


// if we can add password2change() as a once event listener, can do it this way - only display doesn't match message after password2 is changed once
// function password2change() {
//   console.log('password2change');
//   const password2 = document.forms['signUp-form'].elements.password2;
//   const password1 = document.forms['signUp-form'].elements.password1;
//   // password2.removeEventListener('onInput', password2change);
//   password2.addEventListener('input', checkPasswordsMatch);
//   password1.addEventListener('input', checkPasswordsMatch);
//   checkPasswordsMatch();
// }


function checkPasswordsMatch() {
  console.log('check');
  const form = document.forms['signUp-form'];
  const password1 = form.elements.password1.value;
  const password2 = form.elements.password2.value;
  if (password1 !== password2) {
    displayPasswordError("Passwords don't match");
  } else {
    displayPasswordError("");
  }
}

function signupHandler(event) {
  event.preventDefault();

  const form = document.forms['signUp-form'];
  const username = form.elements.username.value;
  const email = form.elements.email.value;
  const password1 = form.elements.password1.value;
  const password2 = form.elements.password2.value;

  // put username validity and password requirements in the html?
  if (username && password1 && password2 && email) {
    if (!usernameValid(username)) {
      alert('Invalid username');
    } else if (!passwordValid(password1)) {
      alert('Invalid password');
    } else if (password1 !== password2) {
      alert('Passwords not matching')
    } else {
      let formData = new FormData();
      formData.append("username", username);
      formData.append("password", password1);
      formData.append("email", email);
      fetch(`${API_URL}/users`, { method: 'post', body: formData })
        .then(resp => {
          resp.json().then(data => {
            if (resp.status === 201) {
              // document.cookie = `token=${data.token}`;
              window.localStorage.setItem('token', data.token);
              // redirect to homepage
            } else {
              displaySignupError(data.error);
            }
          })
        })
        .catch(error => { // will this catch error from resp.json()?
          displayError(error);
        });
    }
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
              <p class="form-info">3-64 characters. May contain uppercase and lowercase letters, numbers, - and _</p>
              <input type="text" id="username-input" name="username" required minlength="3" maxlength="64" pattern="[a-zA-z0-9_-]+" title="3-64 characters. May contain uppercase and lowercase letters, numbers, - and _"/>
            </div>
            <div>
              <p id="email-text">Email</p>
              <input type="email" id="email-input" name="email" required pattern="[a-zA-z0-9%+_.-]+@[a-zA-Z0-9.-]+\.[A-Za-z0-9]+" maxlength="100"/>
            </div>
            <div>
              <p id="password-text">Password</p>
              <p class="form-info">10-64 characters. Must contain a lower case letter and at least one number, uppercase letter or symbol (!@#$%^&amp;*()_-+={}]:;'&quot;&lt;&#44;&gt;.?/|\~`).</p>
              <input type="password" id="password-input" name="password1" onInput={checkPasswordsMatch} required minlength="8" maxlength="64" pattern="(?=.*[a-z])((?=.*\d)|(?=.*[A-Z])|(?=.*[!@#$%^&amp;*()_\-+=\{}\]:;'&quot;<,>.?\/|\\~`])).{0,}"/>
            </div>
            <div>
              <p id="password-text">Confirm Password</p> {/* two have the same id */}
              <input type="password" id="password-input" name="password2" required onInput={checkPasswordsMatch}/> {/* should use once attribute */}
            </div>
            <p class="password-info"></p>
            <button id="signUp-btn-2" type="submit" onClick={signupHandler}>Sign Up</button>
          </form>
        </div>
      </div>
    </div>
  )
}

export default SignUp;
