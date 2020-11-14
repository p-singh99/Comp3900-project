import React, {useState, useEffect, useRef} from 'react';
import {Link} from 'react-router-dom';
import './../css/Header.css';
import logo from './../images/logo.png';
import DropDownMenu from './../components/DropDownMenu';
//import Search from './../components/Search.js';
// import Search from './../components/SearchPage.js';
import notifications from './../images/notifications.png';
import settings from './../images/settings.png';
import {logoutHandler, authFailed, isLoggedIn, getUsername} from './../auth-functions';
import { useHistory } from 'react-router-dom';
import {API_URL} from './../constants';
import Notifications from './../components/Notifications';

function displayError(error) {
  alert(error);
}

let mouseDownEvent = false;


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

  let [isStart, setStart] = useState(true);
  let [options, setOptions] = useState({options: [], visibility: 'hidden'})
  let [notificationClicked, setNotificationClicked] = useState(false);
  let [settingsClicked, setSettingsClicked] = useState(false);
  let [selectedIcon, setSelectedIcon] = useState('');
  const dropDownRef = useRef(DropDownMenu);

  const imgStyle = {
    float: "left",
    margin: '0px 10px 0px 0px'
  }
  const textStyle = {
    margin: '0px 0px 0px 0px',
    fontSize: '21px',
    color: '#64CFEB'
  }

  let start = true;
  /*
  useEffect(() => {
    //console.log('called');
    if (!isStart) {
      if (selectedIcon == Icons.NOTIFICATION) {
        checkNotificationsClicked();
      } else if (selectedIcon == Icons.SETTINGS) {
        checkSettingsClicked();
      }
    }
    setStart(false);
  }, [notificationClicked, settingsClicked, setOptions]);

  function checkNotificationsClicked() {
    if (notificationClicked) {
      document.getElementById('notification-button').setAttribute('id', 'notification-button-clicked');
      if (settingsClicked) {
        setSettingsClicked(false);
        setSelectedIcon(Icons.SETTINGS);
      }
      setOptions({options: [], visibility: 'visible'});
    } else {
      document.getElementById('notification-button-clicked').setAttribute('id', 'notification-button');
      if (settingsClicked) {
        setOptions({options: settingsOptions, visibility: 'visible'});
      } else {
        setOptions({options: [], visibility: 'hidden'});
      }
    }
  }

  function checkSettingsClicked() {
    // console.log('called');
    if (settingsClicked) {
      document.getElementById('settings-button').setAttribute('id', 'settings-button-clicked');
      if (notificationClicked) {
        setNotificationClicked(false);
        setSelectedIcon(Icons.NOTIFICATION);
      }
      setOptions({options: settingsOptions, visibility: 'visible'});
    } else {
      document.getElementById('settings-button-clicked').setAttribute('id', 'settings-button');
      if (notificationClicked) {
        setOptions({options: [], visibility: 'visible'});
      } else {
        setOptions({options: settingsOptions, visibility: 'hidden'});
      }
    }
  }

  function clickedOutside() {
    setSettingsClicked(false);
    setNotificationClicked(false);
  }
  */
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
            //setNotificationClicked(!notificationClicked);
            //setSelectedIcon(Icons.NOTIFICATION);
          }}/>
          <button id="settings-button" onClick={() => {
            setSettingsVisibility(!settingsVisibility);
            setNotificationsVisibility(false);
            //setSettingsClicked(!settingsClicked);
            //setSelectedIcon(Icons.SETTINGS);
          }}/>
        </div>
      </div>
      <div id="notificationsDiv">
        <Notifications ref= {dropDownRef} clickedOutside={null} state={notifications} setState={setNotifications} visibility={notificationsVisibility}/>
      </div>
      <div id="dropDownDiv">
        <DropDownMenu ref={dropDownRef} items={{options: settingsOptions}} visibility={settingsVisibility} clickedOutside={null}/>
      </div>
    </div>
  )
}

export default Header;
