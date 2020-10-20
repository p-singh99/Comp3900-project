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
        <NavLink className="nav-item" exact to="/" activeClassName="active"><li>Home</li></NavLink>
        <NavLink className="nav-item" exact to="/history" activeClassName="active"><li>History</li></NavLink>
        <NavLink className="nav-item" exact to="/recommended" activeClassName="active"><li>Recommended</li></NavLink>
        <NavLink className="nav-item" exact to="/subscriptions" activeClassName="active"><li>Subscriptions</li></NavLink>
        <NavLink className="nav-item" exact to="/about" activeClassName="active"><li>About</li></NavLink>
      </ul>
    </div>
  )
}

export default NavBar;
