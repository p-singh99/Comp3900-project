import React, {useState, useEffect, useRef} from 'react';
import {Link} from 'react-router-dom';
import './../css/Header.css';
import logo from './../images/logo.png';
import DropDownMenu from './../components/DropDownMenu';
//import Search from './../components/Search.js';
// import Search from './../components/SearchPage.js';
import notifications from './../images/notifications.png';
import settings from './../images/settings.png';
import {logoutHandler, authFailed, isLoggedIn, getUsername, fetchAPI} from './../auth-functions';
import { useHistory } from 'react-router-dom';
import {API_URL} from './../constants';
import Notifications from './../components/Notifications';

function displayError(error) {
  alert(error);
}

let mouseDownEvent = false;
let intervalSet = false;


const Icons = {
  NOTIFICATION: 'notification',
  SETTINGS: 'settings'
}

function Header() {
  const history = useHistory();

  const settingsOptions = isLoggedIn() ?
  [
    {text: 'Logout', onClick: logoutHandler},
    {text: 'Account settings', onClick: () => history.push("/settings")}
  ]
  :
  [
    {text: 'Login', onClick: () => history.push("/login")},
    {text: 'Signup', onClick: () => history.push("/signup")}
  ];

  const imgStyle = {
    float: "left",
    margin: '0px 10px 0px 0px'
  }
  const textStyle = {
    margin: '0px 0px 0px 0px',
    fontSize: '21px',
    color: '#64CFEB'
  }

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

      // being fetched both here and on the actual search page?
      // fetch(`${API_URL}/podcasts?search_query=`+searched_text.value+'&offset=0&limit=50', {method: 'get'})
      //   .then(resp => {
      //     resp.json().then(podcasts => {
      //       if (resp.status === 200) {
      //         // console.log(podcasts[0].title);
      //         // history.push("/search" + "?" + searched_text.value);
      //         // history.push("/search" + "?" + searched_text.value, {podcasts: podcasts});
      //       } else {
      //         // should never enter this
      //         console.log('response status is not 200 after search');
      //       }
      //     })
      //   })
      //   .catch(error => { // will this catch error from resp.json()?
      //   displayError(error);
      // });
    }
  }

  // notifications state
  const [notifications, setNotifications] = useState([]);
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
         <Link to="/" style={{textDecoration: 'none', display: 'flex'}}>
            <img id="logo" 
              style={imgStyle} 
              src={logo} 
              alt="Logo" 
              height={50} 
              width={50}
            />
            <p style={textStyle}> BroJogan <br /> Podcast </p>
          </Link>

        </React.Fragment>
        <div id="search-div" style={{margin: '15px 0px 0px 0px'}}>
          <form id = "search-form" onSubmit = {searchHandler}>
            <input type='text' id='search-input' name='searchComponent' placeholder='Search'/>
              <button id="search-btn" type="submit">Go</button>
          </form>
        </div>
        <div id="icons-div" style={{margin: '15px 25px 0px 0px'}}>
        <div id="username">{getUsername()}</div>
          <button id="notification-button" onClick={() => {
            setNotificationsVisibility(!notificationsVisibility);
            setSettingsVisibility(false);
          }}/>
          <button id="settings-button" onClick={() => {
            setSettingsVisibility(!settingsVisibility);
            setNotificationsVisibility(false);
          }}/>
        </div>
      </div>
      <div id="notificationsDiv">
        <Notifications /*state={notifications} setState={setNotifications}*/ visibility={notificationsVisibility} />
      </div>
      <div id="dropDownDiv">
        <DropDownMenu items={{options: settingsOptions}} visibility={settingsVisibility} />
      </div>
    </div>
  )
}

export default Header;
