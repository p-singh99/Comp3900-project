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

function displayError(error) {
  alert(error);
}


const Icons = {
  NOTIFICATION: 'notification',
  SETTINGS: 'settings'
}

const notificationOptions = [
  {text: 'Notification 1', onClick: () => alert('notification')},
  {text: 'Notification 2', onClick: () => alert('notification')},
  {text: 'Notification 3', onClick: () => alert('notification')},
  {text: 'Notification 4', onClick: () => alert('notification')}
]

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
  let [options, setOptions] = useState({options: notificationOptions, visibility: 'hidden'})
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
      setOptions({options: notificationOptions, visibility: 'visible'});
    } else {
      document.getElementById('notification-button-clicked').setAttribute('id', 'notification-button');
      if (settingsClicked) {
        setOptions({options: settingsOptions, visibility: 'visible'});
      } else {
        setOptions({options: notificationOptions, visibility: 'hidden'});
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
        setOptions({options: notificationOptions, visibility: 'visible'});
      } else {
        setOptions({options: settingsOptions, visibility: 'hidden'});
      }
    }
  }

  function clickedOutside() {
    setSettingsClicked(false);
    setNotificationClicked(false);
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
            setNotificationClicked(!notificationClicked);
            setSelectedIcon(Icons.NOTIFICATION);
          }}/>
          <button id="settings-button" onClick={() => {
            setSettingsClicked(!settingsClicked);
            setSelectedIcon(Icons.SETTINGS);
          }}/>
        </div>
      </div>
      <div id="dropDownDiv">
        <DropDownMenu ref={dropDownRef} items={options} clickedOutside={clickedOutside}/>
      </div>
    </div>
  )
}

export default Header;
