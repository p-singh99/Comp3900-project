import React from 'react';
import './../css/Header.css';
import logo from './../images/logo.png';
import notifications from './../images/notifications.png';
import settings from './../images/settings.png';

function Header() {

  const imgStyle = {
    float: "left",
    margin: '0px 10px 0px 0px'
  }
  const textStyle = {
    margin: '0px 0px 0px 0px',
    fontSize: '21px',
    color: '#64CFEB'
  }

  return (
    <div id="header-div">
      <React.Fragment>
        <img id="logo" 
          style={imgStyle} 
          src={logo} 
          alt="Logo" 
          height={50} 
          width={50}
        />
        <p style={textStyle}> BroJogan <br /> Podcast </p>
      </React.Fragment>
      <div id="search-div" style={{margin: '15px 0px 0px 0px'}}>
        <form>
          <input type='text' id='search-input' name='searchComponent' placeholder='Search'/>
        </form>
      </div>
      <div id="settings-div" style={{margin: '15px 25px 0px 0px'}}>
        <img id="notifications-icon"  
            style={{margin: '0px 10px 0px 0px'}}
            src={notifications} 
            alt="Notifications" 
            height={30} 
            width={30}
        />
        <img id="settings-icon"
          src={settings} 
          alt="Settings" 
          height={30} 
          width={30}
        />
      </div>
    </div>
  )
}

export default Header;
