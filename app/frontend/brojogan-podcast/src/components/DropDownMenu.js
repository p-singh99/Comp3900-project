import React, { useEffect } from 'react'; // useState, useRef
import { Link } from 'react-router-dom';
import './../css/DropDownMenu.css';

function DropDownMenu({ items, visibility }) {

  useEffect(() => {
    console.log("setting settings visibility to " + visibility);
    document.getElementById("dropDown-div").style.visibility = visibility;
  }, [visibility])

  return (
    <React.Fragment>
      <div id='dropDown-div' style={{ visibility: visibility ? "visible" : "hidden" }} >
        {items.options.map(item => {
          return (
            <React.Fragment key={item.key}>
              {item.onClick
                ? <p onClick={item.onClick} style={{ cursor: 'pointer' }}>{item.text}</p>
                : <Link to={item.link}><p>{item.text}</p></Link>
              }
            </React.Fragment>
          )
        })}
      </div>
    </React.Fragment>
  )
}

export default DropDownMenu;


// let menuRef = useRef();
//let [visible, setVisible] = useState(false);

/*
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
*/
