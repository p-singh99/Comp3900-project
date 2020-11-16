import React, { useState } from 'react'; // useEffect, useRef
import { Link } from 'react-router-dom';
import './../css/Header.css';
import logo from './../images/logo.png';
import DropDownMenu from './../components/DropDownMenu';
import { logoutHandler, isLoggedIn, getUsername } from './../authFunctions';
import { useHistory } from 'react-router-dom';
import Notifications from './../components/Notifications';
// import Search from './../components/Search.js';
// import Search from './../components/SearchPage.js';
// import notifications from './../images/notifications.png';
// import settings from './../images/settings.png';

function displayError(error) {
  alert(error);
}

let mouseDownEvent = false;
// let intervalSet = false;


// const Icons = {
//   NOTIFICATION: 'notification',
//   SETTINGS: 'settings'
// }

function Header() {
  const history = useHistory();

  const settingsOptions = isLoggedIn() ?
    [
      { text: 'Logout', onClick: logoutHandler },
      // {text: 'Account settings', onClick: () => history.push("/settings")}
      { text: 'Account settings', link: "/settings" }
    ]
    :
    [
      // {text: 'Login', onClick: () => history.push("/login")},
      // {text: 'Signup', onClick: () => history.push("/signup")}
      { text: 'Login', link: "/login" },
      { text: 'Signup', link: "/signup" }
    ];

  function searchHandler(event) {
    event.preventDefault();
    const form = event.target;
    const searched_text = form.elements.searchComponent;
    if (searched_text) {
      let formData = new FormData(form);
      console.log("formData is");
      console.log(formData);
      console.log("searched_text is ");
      console.log(searched_text);
      console.log(searched_text.value);

      history.push("/search" + "?" + searched_text.value);
      // window.location.href = "/search" + "?" + searched_text.value;
    }
  }

  // notifications state
  // const [notifications, setNotifications] = useState([]);
  const [notificationsVisibility, setNotificationsVisibility] = useState(false);
  const [settingsVisibility, setSettingsVisibility] = useState(false);


  // code for closing drop downs on a mouse click outside of the dropdowns
  // doesn't work right now
  /*
    if (!mouseDownEvent) {
      mouseDownEvent = true;
      document.addEventListener("mousedown", e => {
        let notificationsDiv = document.getElementById("notifications-div");
        let settingsDiv = document.getElementById("dropDown-div");
        if (!notificationsDiv.contains(e.target)) {
          console.log("target not in notifications -> falsing visibility");
          setNotificationsVisibility(false);
        }
        if (!settingsDiv.contains(e.target)) {
          console.log("target not in settings -> falsing visibility");
          setSettingsVisibility(false);
        }
      });
    }
  */
  return (
    <div id="header-wrapper">
      <div id="header-div">
        <React.Fragment>
          <Link to="/" id="header-logo">
            <img id="logo"
              src={logo}
              alt="Logo"
            />
            <p> BroJogan <br /> Podcast </p>
          </Link>

        </React.Fragment>
        <div id="search-div">
          <form id="search-form" onSubmit={searchHandler}>
            <input type='text' id='search-input' name='searchComponent' placeholder='Search' />
            <button id="search-btn" type="submit">Go</button>
          </form>
        </div>
        <div id="icons-div">
          <div id="username">{getUsername()}</div>
          <button id="notification-button" onClick={() => {
            setNotificationsVisibility(!notificationsVisibility);
            setSettingsVisibility(false);
          }} />
          <button id="settings-button" onClick={() => {
            setSettingsVisibility(!settingsVisibility);
            setNotificationsVisibility(false);
          }} />
        </div>
      </div>
      <div id="notificationsDiv">
        <Notifications /*state={notifications} setState={setNotifications}*/ visibility={notificationsVisibility} />
      </div>
      <div id="dropDownDiv">
        <DropDownMenu items={{ options: settingsOptions }} visibility={settingsVisibility} />
      </div>
    </div>
  )
}

export default Header;
