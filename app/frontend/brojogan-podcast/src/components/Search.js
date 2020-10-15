import React, {useEffect, useState} from 'react';
import Select from 'react-select';

const scaryAnimals = [
  {label: "Hello Internet         |       Subs: 2", value: 1, subscribers : 2, author: "CGP Grey and Brady Haran", description : "Presented by CGP Grey and Dr. Brady Haran."},
  {label: "Hardcore History       |      Subs: 3", value: 2, subscribers : 3, author: "Dan Carlin", description : "Hardcore History is Carlins forum for exploring topics throughout world history. The focus of each episode varies widely from show to show but they are generally centered on specific historical events and are discussed in a"},
  {label: "Chapo Trap House       |     Subs: 2", value: 3, subscribers : 2, author: "Chapo Trap House", description : "Chapo Trap House is an American political podcast founded in March 2016 and hosted by Will Menaker, Matt Christman, Felix Biederman, Amber A'Lee Frost, and Virgil Texas."},
  {label: "99% Invisible          |    Subs: 2", value: 4, subscribers : 2, author: "Roman Mars", description : "Design is everywhere in our lives, perhaps most importantly in the places where we've just stopped noticing. 99% Invisible is a weekly exploration of the process and power of design and architecture. From award winning producer Roman Mars. Learn more at "},
  
];

const customStyles = {
  control: (base, state) => ({
    ...base,
    background: "#2E2B3F",
    // match with the menu
    borderRadius: 50,
    // Overwrittes the different states of border
    borderColor: state.isFocused ? "#0ABA6C" : "#64CFEB",
    borderWidth: "2px",
    // Removes weird border around container
    boxShadow: state.isFocused ? null : null,
    color: '#64CFEB',
  }),
  menu: base => ({
    ...base,
    // override border radius to match the box
    borderRadius: 10,
    // kill the gap
    marginTop: 0,
    color: '#64CFEB',
    borderColor: '#0ABA6C',
    borderWidth: "2px",
  }),
  menuList: base => ({
    ...base,
    // kill the white space on first and last option
    padding: 0,
    borderRadius: 10,
    background: '#2E2B3F',
    color: '#64CFEB',
    borderColor: '#0ABA6C',
    borderWidth: "2px",
  }),
  placeholder: base => ({
    ...base,
    color: '#64CFEB',
  }),
  singleValue: base => ({
    ...base,
    color: '#64CFEB',
  }),
  input: base => ({
    ...base,
    color: 'white',
  })
};

export default function Search() {

  let [searchValue, setSearchvalue] = useState({});

  useEffect(() => {
    console.log(`Value: ${searchValue.label}`);

  }, [searchValue])

  function changeHandler(value) {
    // console.log(value);
    setSearchvalue(value);
  }

  // function getvalue(value) {
  //   if (value) {
  //     console.log(`Live value ${value}`);
  //   }
  // }

  return (
    <React.Fragment>
      <Select id="input-box" 
        options={scaryAnimals} 
        styles={customStyles} 
        placeholder={'Search'} 
        onChange={changeHandler} 
        /*inputValue={getvalue}*/ 
        
        />
    </React.Fragment>
  )
}
