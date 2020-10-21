import React from 'react';
import './../css/SignUp.css';
import logo from './../images/logo.png';
import { API_URL } from './../constants';
import {saveToken} from './../auth-functions'
import {useHistory} from 'react-router-dom';
import { Helmet } from 'react-helmet';
import { checkPassword, checkPasswordsMatch, checkField } from './../validation-functions';


// General error eg network error
// function displayError(error) {
//   alert(error);
// }

function displaySignupError(msg) {
  let errorElem = document.getElementById("signup-error");
  errorElem.textContent = msg;
  errorElem.style.visibility = 'visible'
}

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

function SignUp() {
  const history = useHistory();

  function signupHandler(event) {
    event.preventDefault();
  
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
      fetch(`${API_URL}/users`, { method: 'post', body: formData })
        .then(resp => {
          resp.json().then(data => {
            if (resp.status === 201) {
              saveToken(data);
              // window.location.replace("/home");
              history.push("/");
            } else {
              displaySignupErrors(data.error);
            }
          })
        })
        .catch(error => { // will this catch error from resp.json()?
          displaySignupError('Network or other error');
        });
    }
  }


  return (
    <div id='wrapper'>
      <Helmet>
        <title>Brojogan Podcasts - Signup</title>
      </Helmet>
      
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
              { <p className="form-info">3-64 characters. May contain lowercase letters, numbers, - and _</p> }
              {/* <input type="text" id="username-input" name="username" required onChange={checkUsername} minlength="3" maxlength="64" pattern="[a-zA-z0-9_-]+" title="3-64 characters. May contain uppercase and lowercase letters, numbers, - and _"/> */}
              <input type="text" id="username-input" name="username" onChange={checkField} minLength="3" maxLength="64" pattern="[a-zA-z0-9_-]{3,64}" title="3-64 characters. May contain uppercase and lowercase letters, numbers, - and _"/>
              { <p id="username-error" className="error">Invalid username</p> }
            </div>
            <div>
              <p id="email-text">Email</p>
              <input type="email" id="email-input" name="email" onChange={checkField} pattern="[a-zA-Z0-9%+_.-]+@[a-zA-Z0-9.-]+\.[A-Za-z0-9]+" maxLength="100"/>
              { <p id="username-error" className="error">Invalid email address</p> }
            </div>
            <div>
              <p className="password-text">Password</p>
              { <p className="form-info">10-64 characters. Must contain a lower case letter and at least one number, uppercase letter or symbol (!@#$%^&amp;*()_-+={}]:;'&quot;&lt;&#44;&gt;.?/|\~`).</p> }
              <input type="password" className="password-input" name="password1" onInput={checkPassword} minLength="10" maxLength="64" pattern="(?=.*[a-z])((?=.*\d)|(?=.*[A-Z])|(?=.*[!@#$%^&amp;*()_\-+=\{}\]:;'&quot;<,>.?\/|\\~`])).{0,}"/>
            </div>
            <div>
              <p className="password-text">Confirm Password</p> {/* two have the same id */}
              <input type="password" className="password-input" name="password2" onInput={checkPasswordsMatch}/> {/* should use once attribute */}
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
