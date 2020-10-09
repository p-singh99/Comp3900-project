import React from 'react';
import './../css/NavBar.css';
import logo from './../images/logo.png';

function NavBar() {

  const divStyle = {
    padding: '0px'
  }

  return (
    <div id='navBar-div' style={divStyle}>
      <ul>
        <li><a href="#" />Home</li>
        <li><a href="#" />History</li>
        <li><a href="#" />Recommended</li>
        <li><a href="#" />Subscriptions</li>
        <li><a href="#" />About</li>
      </ul>
    </div>
  )
}

export default NavBar;
