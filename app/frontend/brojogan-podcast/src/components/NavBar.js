import React, { useState, useEffect } from 'react';
import { NavLink } from 'react-router-dom'; // withRouter
import { BiHomeAlt } from 'react-icons/bi';
import { AiOutlineHistory } from 'react-icons/ai';
import { FiThumbsUp } from 'react-icons/fi';
import { MdSubscriptions } from 'react-icons/md';
import { BsInfoCircle } from 'react-icons/bs';
import { GiHamburgerMenu } from 'react-icons/gi';
import { isLoggedIn } from '../authFunctions';
import './../css/NavBar.css';

function NavBar() {

  const [expanded, setExpanded] = useState(false);

  useEffect(() => {
    if (!expanded) {
      document.getElementById('navBar-div').setAttribute('id', 'navBar-div-collapsed');
      const elemenntsToHide = document.getElementsByClassName('navBar-p');
      for (let item of elemenntsToHide) {
        item.style['visibility'] = 'hidden';
        item.style['display'] = 'none';
      }
      document.getElementById('content-div-main').style.marginLeft = '50px';
    } else {
      document.getElementById('navBar-div-collapsed').setAttribute('id', 'navBar-div');
      const elementsToShow = document.getElementsByClassName('navBar-p');
      for (let item of elementsToShow) {
        item.style['visibility'] = 'visible';
        item.style['display'] = 'block';
      }
      document.getElementById('content-div-main').style.marginLeft = '210px';
    }
  }, [expanded]);

  const divStyle = {
    padding: '0px'
  }

  return (
    <div id='navBar-div' style={divStyle}>
      <GiHamburgerMenu id="hamburger-icon" style={{ marginLeft: "15px", marginTop: "40px" }} onClick={() => {
        setExpanded(!expanded);
      }} />
      <ul>
        <NavLink className="nav-item" exact to="/" activeClassName="active"><li><div className="navBar-li"><BiHomeAlt /><p className="navBar-p">Home</p></div></li></NavLink>
        {isLoggedIn()
          ?
          <React.Fragment>
          <NavLink className="nav-item" exact to="/history" activeClassName="active"><li><div className="navBar-li"><AiOutlineHistory /><p className="navBar-p">History</p></div></li></NavLink>
          <NavLink className="nav-item" exact to="/recommended" activeClassName="active"><li><div className="navBar-li"><FiThumbsUp /><p className="navBar-p">Recommended</p></div></li></NavLink>
          <NavLink className="nav-item" exact to="/subscriptions" activeClassName="active"><li><div className="navBar-li">< MdSubscriptions /><p className="navBar-p">Subscriptions</p></div></li></NavLink>
          </React.Fragment>
        : null}
        <NavLink className="nav-item" exact to="/about" activeClassName="active"><li><div className="navBar-li">< BsInfoCircle /><p className="navBar-p">About</p></div></li></NavLink>
      </ul>
    </div>
  )
}

export default NavBar;
