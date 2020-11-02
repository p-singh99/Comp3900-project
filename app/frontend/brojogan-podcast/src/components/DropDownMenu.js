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
        {props.items.options.map(item => {
            return <p onClick={item.onClick} style={{cursor: 'pointer'}}>{item.text}</p>          
        })}
      </div>
    </React.Fragment>
  )
}

export default DropDownMenu;
