import React, { useEffect, useState } from 'react';
import Modal from 'react-bootstrap/Modal';
import { Helmet } from 'react-helmet';
import {FiUser} from 'react-icons/fi';

import { checkPassword, checkPasswordsMatch } from './../validationFunctions';
import { fetchAPI, logoutHandler, getUsername } from './../authFunctions';

import './../css/Settings.css';
import './../css/bootstrap-modal.css'; // get rid of this, bootstrap css is already imported


// handler for delete account modal delete button
function handleDelete(event) {
  event.preventDefault();
  // check that they entered a password
  const password = document.getElementById("delete-password-input").value;
  if (!password) {
    return;
  }

  let body = { "password": password };
  document.getElementById("delete-error").textContent = "...";
  fetchAPI('/users/self', 'delete', body)
    .then(() => {
      alert("Success. Account deleted.");
      logoutHandler();
    })
    .catch(err => {
      document.getElementById("delete-error").textContent = err.toString();
    });
}

function Settings() {
  const [currentEmail, setCurrentEmail] = useState("");
  const [error, setError] = useState("");
  const [deleteShow, setDeleteShow] = useState(false); // whether delete account modal is shown
  const [disabled, setDisabled] = useState(true); // whether delete account modal button is disabled

  function displayMessage(msg) {
    setError(msg.toString());
  }

  // for delete account modal: when entered username is correct, enable delete button
  function checkUsername(event) {
    if (event.target.value === getUsername()) {
      setDisabled(false);
    } else {
      setDisabled(true);
    }
  }

  function hideModal() {
    setDeleteShow(false);
    setDisabled(true);
  }

  // handler for settings submit button
  function settingsHandler(event) {
    event.preventDefault();

    const form = event.target;
    const email = form.elements.email;
    const oldPassword = form.elements["old-password"];
    const password1 = form.elements.password1;
    const password2 = form.elements.password2;

    console.log(email.validity);

    // if email or newpassword are empty or unchanged, send value as null
    if ((! email.value || (currentEmail && email.value === currentEmail)) && !password1.value) {
      displayMessage("You haven't made any changes.");
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
      setError("..."); // loading message
      // confirmation popup?
      fetchAPI('/users/self/settings', 'put', data)
        .then(() => {
          displayMessage("Success");
          if (email.value) {
            setCurrentEmail(email.value); // update email display in form
          }
          // refresh?
        })
        .catch(err => {
          displayMessage(err + ". " + "No changes were made to your account.");
        });
    }
  }

  // on page load, fetch current settings ie current email address to display
  useEffect(() => {
    // using DOM .value instead of React because React uses defaultValue, so it gets set again
    // on every re-render, overwriting the user's input
    document.getElementById("new-email-input").value = "Loading...";
    const fetchEmail = async () => {
      try {
        const data = await fetchAPI('/users/self/settings');
        if (data.email) {
          setCurrentEmail(data.email);
          document.getElementById("new-email-input").value = data.email;
        }
      } catch (error) {
        document.getElementById("new-email-input").value = "Error";
        console.log(error);
        displayMessage(error);
      }
    }
    fetchEmail();
  }, []);

  return (
    <div id="settings">
      <Helmet>
        <title>Brojogan Podcasts - Settings</title>
      </Helmet>

      <div className="page-heading">
        <h2>Account Settings</h2>
      </div>

      <div id="account-icon-container">
        <div id="user-icon">
          <FiUser 
            id='user-icon' 
            color="yellow" 
            size="2.5em"
          />
        </div>
        {getUsername()}
      </div>
      
      <form id="settings-form" onSubmit={settingsHandler}>
        <div className="settings-row">
          <label htmlFor="new-email-input">Email</label>
          {/* <input type="email" id="new-email-input" name="email" required className="settings" pattern="[a-zA-Z0-9%+_.-]+@[a-zA-Z0-9.-]+\.[A-Za-z0-9]+" maxLength="100" /> */}
          <input type="email" id="new-email-input" name="email" required className="settings-input" maxLength="100" />
        </div>
        <div className="settings-row">
          <label htmlFor="new-password-input1">New password</label>
          <input type="password" id="new-password-input1" className="settings-input" name="password1" onInput={(event) => checkPassword(event, document.forms["settings-form"])} minLength="10" maxLength="64" pattern="(?=.*[a-z])((?=.*\d)|(?=.*[A-Z])|(?=.*[!@#$%^&amp;*()_\-+=\{}\]:;'&quot;<,>.?\/|\\~`])).{0,}" /> {/* should use once attribute */}
          <p className="form-info">10-64 characters. Must contain a lower case letter and at least one number, uppercase letter or symbol (!@#$%^&amp;*()_-+={}]:;'&quot;&lt;&#44;&gt;.?/|\~`).</p>
        </div>
        <br />
        <div className="settings-row">
          <label htmlFor="new-password-input2">Confirm new password</label>
          <input type="password" id="new-password-input2" className="settings-input" name="password2" onInput={(event) => checkPasswordsMatch(event, document.forms["settings-form"])} /> {/* should use once attribute */}
          <p id="password-error" className="error">Placeholder</p>
        </div>
        <div className="settings-row">
          <label htmlFor="old-password-input">Current password</label>
          <input type="password" className="settings-input" name="old-password" required />
          <p className="form-info">Enter your current password to confirm your identity.</p>
        </div>
        {/* <p id="signup-error" className="error">Placeholder</p> */}
        <button type="submit" className="settings-btn">Save changes</button>
        <p className="settings-error">{error}</p>
      </form>
      <hr />

      <h2 id="delete-heading">Delete Account</h2>
      <p>This action is permanent and cannot be undone. This will delete your account including all subscriptions, listening history and ratings.</p>
      <button id="delete-btn-settings" className="settings-btn delete-btn" onClick={() => setDeleteShow(true)}>Delete Account</button>

      {/* Popup for deleting account */}
      <Modal show={deleteShow} onHide={hideModal}>
        <Modal.Header closeButton>
          <Modal.Title>Are you sure you want to delete your account?</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          Confirm that you want to delete your account by entering your username and password:
          <form id="delete-form" onSubmit={handleDelete}>
            <label htmlFor="delete-username-input">Username </label>
            <input type="text" id="delete-username-input" className="settings" name="username" onInput={checkUsername} />
            <br /><br />
            <label htmlFor="delete-password-input">Password </label>
            <input type="password" id="delete-password-input" className="settings" name="password" required/>
          </form>
          <p id="delete-error"></p>
        </Modal.Body>
        <Modal.Footer>
          <button className="settings-btn" onClick={hideModal}>Cancel</button>
          <input type="submit" form="delete-form" disabled={disabled} className="settings-btn delete-btn" id="delete-btn" value="Delete my account" />
        </Modal.Footer>
      </Modal>
    </div >
  )
}

export default Settings;
