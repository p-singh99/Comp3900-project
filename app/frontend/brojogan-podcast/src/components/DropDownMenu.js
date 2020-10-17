import React, {useState, useEffect, useRef} from 'react';
import {Link} from 'react-router-dom';
import './../css/DropDownMenu.css';

function DropDownMenu(props) {

  let menuRef = useRef();
  let [visible, setVisible] = useState(false);

  useEffect(() => {
    let handler = (event) => {
      if (!menuRef.current.contains(event.target)) {
        const div = document.getElementById('dropDown-div');
        // div.style.visibility = 'hidden';
        props.clickedOutside();
      }
    };

    document.addEventListener("mousedown", handler);
    console.log('Changed');
    const div = document.getElementById('dropDown-div');
    div.style.visibility = props.items.visibility;
    //setVisible(props.items.visibility);

    return () => {
      document.removeEventListener("mousedown", handler);
    }
  }, [props]);

  return (
    <React.Fragment>
      <div id='dropDown-div' ref={menuRef}>
        {/* <Link to="/login">home</Link> */}
        {props.items.options.map(item => {
          // return <p>{item}</p>
          // const link = '/' + {item};
          //if ({item} == 'login') {
            // return <a id = "login-home-header" href='/login'>{item}</a>
            // return <Link to={item.link}>{item.text}</Link>
            // return <a id = "login-home-header" href={item.link}>{item.text}</a>
            return <p onClick={item.onClick} style={{cursor: 'pointer'}}>{item.text}</p>
          // } else {
          //   return <a href='#'>{item}</a>
          // }
          
        })}
      </div>
    </React.Fragment>
  )
}

export default DropDownMenu;
