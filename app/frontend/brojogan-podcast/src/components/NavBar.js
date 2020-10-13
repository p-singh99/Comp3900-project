import React from 'react';
import './../css/NavBar.css';
import {NavLink, withRouter} from 'react-router-dom';

function NavBar() {

  const divStyle = {
    padding: '0px'
  }

  return (
    <div id='navBar-div' style={divStyle}>
      <ul>
        <li><NavLink className="nav-item" exact to="/" activeClassName="active">Home</NavLink></li>
        <li><NavLink className="nav-item" exact to="/history" activeClassName="active">History</NavLink></li>
        <li><NavLink className="nav-item" exact to="/recommended" activeClassName="active">Recommended</NavLink></li>
        <li><NavLink className="nav-item" exact to="/subscriptions" activeClassName="active">Subscriptions</NavLink></li>
        <li><NavLink className="nav-item" exact to="/about" activeClassName="active">About</NavLink></li>
      </ul>
    </div>
  )
}

export default NavBar;
