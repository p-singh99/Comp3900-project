import React, { useEffect, useState } from 'react';
import Modal from 'react-bootstrap/Modal';
import { Helmet } from 'react-helmet';
import { checkPassword, checkPasswordsMatch, checkField } from './../validation-functions';
import { fetchAPI, logoutHandler, getUsername } from './../auth-functions';
// import { API_URL } from './../constants';
import './../css/Settings.css';
import './../css/bootstrap-modal.css'
// import 'bootstrap/dist/css/bootstrap.min.css';


function handleDelete() {
  // pop up / modal
  // are you sure? Enter username and password to confirm
  const password = document.getElementById("delete-password-input").value;
  if (!password) {
    return;
  }

  let body = { "password": password };
  fetchAPI(`/users/self/settings`, 'delete', body, false)
    .then(() => {
      alert("Success. Account deleted.");
      logoutHandler();
    })
    .catch(err => {
      document.getElementById("error").textContent = err.toString();
    });
}


function Settings() {
  // const [currentEmail, setCurrentEmail] = useState("Leave unchanged to keep current email address");
  const [error, setError] = useState("");
  const [deleteShow, setDeleteShow] = useState(false);
  const [disabled, setDisabled] = useState(true);

  function displayMessage(msg) {
    setError(msg.toString());
  }

  function checkUsername(event) {
    setDisabled(event.target.value !== getUsername());
  }

  function hideModal() {
    setDeleteShow(false);
    setDisabled(true);
  }

  function settingsHandler(event) {
    event.preventDefault();

    const form = event.target;
    const email = form.elements.email;
    const oldPassword = form.elements["old-password"];
    const password1 = form.elements.password1;
    const password2 = form.elements.password2;

    console.log(email.validity);

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
      fetchAPI('/users/self/settings', 'put', data)
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
          // setCurrentEmail(data.email);
          document.getElementById("new-email-input").value = data.email; // instead of currentEmail
        }
      } catch (error) {
        // setCurrentEmail("currentemail@address.com"); // this line is for testing, remove
        document.getElementById("new-email-input").value = "Error"; // for testing
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

      <h1>Account Settings - {window.localStorage.getItem('username')}</h1>
      <form id="settings-form" onSubmit={settingsHandler}>
        <div>
          <label for="new-email-input">Email</label>
          {/* <input type="email" id="new-email-input" name="email" required className="settings" pattern="[a-zA-Z0-9%+_.-]+@[a-zA-Z0-9.-]+\.[A-Za-z0-9]+" maxLength="100" /> */}
          <input type="email" id="new-email-input" name="email" required className="settings" maxLength="100" />
        </div>
        <div>
          <p className="form-info">10-64 characters. Must contain a lower case letter and at least one number, uppercase letter or symbol (!@#$%^&amp;*()_-+={}]:;'&quot;&lt;&#44;&gt;.?/|\~`).</p>
          <label for="new-password-input1">New password</label>
          <input type="password" id="new-password-input1" className="new-password-input settings" name="password1" onInput={(event) => checkPassword(event, document.forms["settings-form"])} minLength="10" maxLength="64" pattern="(?=.*[a-z])((?=.*\d)|(?=.*[A-Z])|(?=.*[!@#$%^&amp;*()_\-+=\{}\]:;'&quot;<,>.?\/|\\~`])).{0,}" /> {/* should use once attribute */}
        </div>
        <br />
        <div>
          <label for="new-password-input2">Confirm new password</label>
          <input type="password" id="new-password-input2" className="new-password-input settings" name="password2" onInput={(event) => checkPasswordsMatch(event, document.forms["settings-form"])} /> {/* should use once attribute */}
          <p id="password-error" className="error">Placeholder</p>
        </div>
        <div>
          <p>Enter your current password to confirm your identity.</p>
          <label for="old-password-input">Current password</label>
          <input type="password" className="old-password-input settings" name="old-password" required />
        </div>
        {/* <p id="signup-error" className="error">Placeholder</p> */}
        <button type="submit" className="settings-btn">Save changes</button>
        <p className="settings-error">{error}</p>
      </form>
      <hr />

      <h2 id="delete-heading">Delete Account</h2>
      <p>This action is permanent and cannot be undone. This will delete your account including all subscriptions, listening history and ratings.</p>
      <button className="settings-btn delete-btn" onClick={() => { console.log("show"); setDeleteShow(true) }}>Delete Account</button>

      {/* Bootstrap requires importing bootstrap css which screws everything up because they couldn't be bothered using bootstrap-specific selectors */}
      <Modal show={deleteShow} onHide={hideModal}>
        <Modal.Header closeButton>
          <Modal.Title>Are you sure you want to delete your account?</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          Confirm that you want to delete your account by entering your username and password:
          <form>
            <label for="delete-username-input">Username </label>
            <input type="text" id="delete-username-input" className="settings" name="username" onInput={checkUsername} />
            <br /><br />
            <label for="delete-password-input">Password </label>
            <input type="password" id="delete-password-input" className="settings" name="password" />
          </form>
          <p id="error"></p>
        </Modal.Body>
        <Modal.Footer>
          <button className="settings-btn" onClick={hideModal}>Cancel</button>
          <button disabled={disabled} className="settings-btn delete-btn" id="delete-btn" onClick={handleDelete}>Delete my account</button>
        </Modal.Footer>
      </Modal>


    </div >
  )
}

export default Settings;
