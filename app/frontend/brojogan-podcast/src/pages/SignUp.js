import React, {useEffect, useState} from 'react';
import {useHistory} from 'react-router-dom';
import { Helmet } from 'react-helmet';

import { API_URL } from './../constants';
import {saveToken} from './../authFunctions'
import { checkPassword, checkPasswordsMatch, checkField } from './../validationFunctions';

import './../css/SignUp.css';
import logo from './../images/logo.png';


function displaySignupError(msg) {
  let errorElem = document.getElementById("signup-error");
  errorElem.textContent = msg;
  errorElem.style.visibility = 'visible'
}
// const placeholder = '3-64 characters including "-" and "_" with lowercase letters and numbers'
// sign up fail eg email already exists
// takes a list
function displaySignupErrors(errors) {
  let errorElem = document.getElementById("signup-error");
  errorElem.textContent = '';
  for (let msg of errors) {
    errorElem.textContent += msg + '.\n';
  }
  errorElem.style.visibility = 'visible';
}

function SignUp() {
  const history = useHistory();

  const [usernameHelpStatus, setUsernameStatus] = useState(false); // whether or not to display username help information
  const [passwordHelpStatus, setPasswordStatus] = useState(false);
  const [pendingRequest, setPendingRequest] = useState(false); // used to prevent multiple in-air requests when button is repeatedly clicked.

  // handler for signup button - check inputs, send signup request and redirect to homepage
  function signupHandler(event) {
    event.preventDefault();
    if (pendingRequest) {
      console.log("Pending request, not sending signup");
      return;
    }
    const form = document.forms['signUp-form'];
    const username = form.elements.username;
    const email = form.elements.email;
    const password1 = form.elements.password1;
    const password2 = form.elements.password2;
    
    if (!username.value || !password1.value || !password2.value || !email.value
        || ! username.validity.valid || ! password1.validity.valid || ! email.validity.valid
        || password1.value !== password2.value) {
          displaySignupError("Please enter all fields correctly.");
    } else {
      let formData = new FormData();
      formData.append("username", username.value);
      formData.append("password", password1.value);
      formData.append("email", email.value);
      setPendingRequest(true);
      fetch(`${API_URL}/users`, { method: 'post', body: formData })
        .then(resp => {
          resp.json().then(data => {
            if (resp.status === 201) {
              saveToken(data);
              // window.sessionStorage.setItem("newuser", true); // maybe - user stays as a new user for their entire first session
              history.push("/", {newUser: true});
            } else {
              displaySignupErrors(data.error);
            }
            setPendingRequest(false);
          })
        })
        .catch(error => { // will this catch error from resp.json()?
          displaySignupError('Network or other error');
          setPendingRequest(false);
        });
    }
  }

  // display/hide username help and password help information
  useEffect(() => {
    // Check if user clicked help for password field
    if (usernameHelpStatus === false) {
      document.getElementById('help-text-username').style.visibility = "hidden";
    } else {
      document.getElementById('help-text-username').style.visibility = "visible";
    }

    // Check if user clicked help for password field
    if (passwordHelpStatus === false) {
      document.getElementById('help-text-password').style.visibility = "hidden";
    } else {
      document.getElementById('help-text-password').style.visibility = "visible";
    }
  }, [passwordHelpStatus, usernameHelpStatus])


  return (
    <div id='wrapper'>
      <Helmet>
        <title>Brojogan Podcasts - Signup</title>
      </Helmet>
      
      <div id='signUp-logo-div'>
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

        <div id='signUp-form-div'>
          <h1>Sign Up</h1>
          <form id="signUp-form">
            
            <div id="username-div">
              <p id="username-text">
                Username
                {/* Username help toggle button */}
                <button
                  className="signup-help-btn" 
                  type="button"
                  onClick = {() => {
                    setUsernameStatus(!usernameHelpStatus);  
                  }}
                >
                  ?
                </button>
                <p className="help-text" id="help-text-username">
                3-64 characters including "-" and "_" with lowercase <br /> letters and numbers.
                </p>
              </p>
              { <p className="form-info"></p> }
              {/* <input type="text" id="username-input" name="username" required onChange={checkUsername} minlength="3" maxlength="64" pattern="[a-zA-z0-9_-]+" title="3-64 characters. May contain uppercase and lowercase letters, numbers, - and _"/> */}
              <input type="text"  id="username-input" name="username" onChange={checkField} minLength="3" maxLength="64" pattern="[a-zA-z0-9_-]{3,64}" title="3-64 characters. May contain uppercase and lowercase letters, numbers, - and _"/>
              { <p id="username-error" className="error">Invalid username</p> }
            </div>

            <div>
              <p id="email-text">Email</p>
              <input type="email" id="email-input" name="email" onChange={checkField} pattern="[a-zA-Z0-9%+_.-]+@[a-zA-Z0-9.-]+\.[A-Za-z0-9]+" maxLength="100"/>
              { <p id="username-error" className="error">Invalid email address</p> }
            </div>

            <div>
              <p className="password-text">
                Password
                {/* Password help toggle button */}
                <button 
                  className="signup-help-btn"
                  type="button" 
                  onClick={() => {
                    setPasswordStatus(!passwordHelpStatus);                   
                  }}
                >
                  ?
                </button>
                <p className="help-text" id="help-text-password">
                10-64 characters. Requires a lowercase letter and at least one number, <br /> uppercase letter or symbol (!@#$%^&amp;*()_-+={}]:;'&quot;&lt;&#44;&gt;.?/|\~`).
                </p>
              </p>
              { <p className="form-info"></p> }
              <input type="password" className="password-input" name="password1" onInput={(event) => checkPassword(event, document.forms["signUp-form"])} required minLength="10" maxLength="64" pattern="(?=.*[a-z])((?=.*\d)|(?=.*[A-Z])|(?=.*[!@#$%^&amp;*()_\-+=\{}\]:;'&quot;<,>.?\/|\\~`])).{0,}"/>
            </div>
            <div>
              <p className="password-text" id="confirm-pswd">Confirm Password</p> {/* two have the same id */}
              <input id="confirm-pswd-input" type="password" className="password-input" name="password2" onInput={(event) => checkPasswordsMatch(event, document.forms["signUp-form"])}/> {/* should use once attribute */}

              { <p id="password-error" className="error">Placeholder</p> }
            </div>
            
            {<pre id="signup-error" className="error">Placeholder</pre> }{ /* pre so that can add new line in textContent */}
            <button id="signUp-btn-2" type="submit" onClick={signupHandler}>Sign Up</button>
          </form>
        </div>
      </div>
    </div>
  )
}

export default SignUp;

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

// function validPassword(pw) {
//   if (pw.length < 10 || pw.length > 64) {
//     return false;
//   }
//   lower = false;
//   upper = false;
//   number = false;
//   symbol = false;
//   count = 0;
//   for (let c of pw) {
//     if ()
//   }
// }
