import React, { useEffect, useState } from 'react'
import { Helmet } from 'react-helmet';
import { checkPassword, checkPasswordsMatch, checkField } from './../validation-functions';
import { fetchAPI, logoutHandler, getUsername } from './../auth-functions';
import { API_URL } from './../constants';
import './../css/settings.css';


function handleDelete() {
  // pop up / modal
  // are you sure? Enter username and password to confirm
  const username = '';
  const password = '';
  if (username !== getUsername()) {
    // display error in popup
    return;
  }

  let body = { "password": password };
  fetchAPI(`/users/self/settings`, 'delete', body, false) // REST would be /users/self
    .then(() => {
      alert("Success. Account deleted.");
      logoutHandler();
    })
    .catch(err => {
      // display err in popup
    });
}

function Settings() {
  const [currentEmail, setCurrentEmail] = useState("Leave unchanged to keep current email address");
  const [error, setError] = useState("");

  function displayMessage(msg) {
    setError(msg.toString());
  }

  function settingsHandler(event) {
    event.preventDefault();

    const form = event.target;
    const email = form.elements.email;
    const oldPassword = form.elements["old-password"];
    const password1 = form.elements.password1;
    const password2 = form.elements.password2;

    if (!email.value && !password1.value) {
      displayMessage("You haven't made any changes.")
    } else if (!oldPassword.value) {
      displayMessage("Please enter current password.");
    } else if (!email.validity.valid || !password1.validity.valid
      || password1.value !== password2.value) {
      displayMessage("Please enter all fields correctly.");
    } else if (password1.value === oldPassword.value) {
      displayMessage("Old password and new password are the same.")
    } else {
      let data = {};
      data.oldpassword = oldPassword.value;
      data.newpassword = password1.value ? password1.value : null;
      data.newemail = email.value ? email.value : null;
      // confirmation popup?
      fetchAPI('/users/self/settings', 'put', data, false)
        .then(() => {
          displayMessage("success");
        })
        .catch(err => {
          displayMessage(err);
        });
    }
  }

  useEffect(() => {
    const fetchEmail = async () => {
      try {
        const data = await fetchAPI('/user/self/settings');
        if (data.email) {
          setCurrentEmail(data.email);
        }
      } catch (error) {
        setCurrentEmail("currentemail@address.com"); // this line is for testing, remove
        console.log(error);
        displayMessage(error);
      }
    }
    fetchEmail();
  }, []);

  return (
    <div>
      <Helmet>
        <title>Brojogan Podcasts - Settings</title>
      </Helmet>

      <h1>Account Settings - {window.localStorage.getItem('username')}</h1>
      <form onSubmit={settingsHandler}>
        <div>
          <label for="new-email-input">Email</label>
          <input type="email" id="new-email-input" name="email" placeholder={currentEmail} onChange={checkField} pattern="[a-zA-Z0-9%+_.-]+@[a-zA-Z0-9.-]+\.[A-Za-z0-9]+" maxLength="100" />
          <p id="username-error" className="error">Invalid email address</p>
        </div>
        <div>
          <p className="form-info">10-64 characters. Must contain a lower case letter and at least one number, uppercase letter or symbol (!@#$%^&amp;*()_-+={}]:;'&quot;&lt;&#44;&gt;.?/|\~`).</p>
          <label for="new-password-input1">New password</label>
          <input type="password" id="new-password-input1" className="new-password-input" name="password1" onInput={checkPassword} minLength="10" maxLength="64" pattern="(?=.*[a-z])((?=.*\d)|(?=.*[A-Z])|(?=.*[!@#$%^&amp;*()_\-+=\{}\]:;'&quot;<,>.?\/|\\~`])).{0,}" /> {/* should use once attribute */}
        </div>
        <div>
          <label for="new-password-input2">Confirm new password</label>
          <input type="password" id="new-password-input2" className="new-password-input" name="password2" onInput={checkPasswordsMatch} /> {/* should use once attribute */}
          <p id="password-error" className="error">Placeholder</p>
        </div>
        <div>
          <p>Enter your current password to confirm your identity.</p>
          <label for="old-password-input">Current password</label>
          <input type="password" className="old-password-input" name="old-password" onInput={checkPassword} />
        </div>
        <p id="signup-error" className="error">Placeholder</p>
        <button type="submit">Change</button>
        <button onClick={handleDelete}>Delete</button>
        <p>{error}</p>
      </form>
    </div >
  )
}

export default Settings;
