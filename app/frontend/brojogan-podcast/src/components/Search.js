import React from 'react';
import Select from 'react-select';

const scaryAnimals = [
  { label: "Alligators", value: 1 },
  { label: "Crocodiles", value: 2 },
  { label: "Sharks", value: 3 },
  { label: "Small crocodiles", value: 4 },
  { label: "Smallest crocodiles", value: 5 },
  { label: "Snakes", value: 6 },
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
  })
};

export default function Search() {
  return (
    <React.Fragment>
      <Select options={scaryAnimals} styles={customStyles} placeholder={'Search'}/>
    </React.Fragment>
  )
}
