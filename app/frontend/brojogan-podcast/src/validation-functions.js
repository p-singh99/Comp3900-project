// change
function displayPasswordError(msg) {
  document.getElementById("password-error").textContent = msg;
  document.getElementById("password-error").style.visibility = 'visible';
}

function removePasswordError() {
  document.getElementById("password-error").style.visibility = 'hidden';
}

export function checkPassword(event, form) {
  const password1Elem = form.elements.password1;
  console.log(password1Elem);
  if (password1Elem.validity.tooShort) {
    displayPasswordError("Password too short");
  } else if (password1Elem.validity.tooLong) {
    displayPasswordError("Password too long");
  } else if (!password1Elem.validity.valid) {
    displayPasswordError("Password missing requirements")
  } else {
    checkPasswordsMatch(event, form);
  }
}

export function checkPasswordsMatch(event, form) {
  const password1 = form.elements.password1.value;
  const password2 = form.elements.password2.value;
  if (password1 !== password2) {
    displayPasswordError("Passwords don't match");
  } else {
    removePasswordError();
  }
}

export function checkField(event) {
  let field = event.target;
  // let correct = /^([a-zA-z0-9_-]{3,64})$/.test(username);
  let errorElem = field.nextSibling;
  if (field.validity.valid) {
    // document.getElementById("username-error").textContent = "";
    // errorID = `${field.id.split("-")[0]}-error`;
    // document.getElementById(errorID).style.visibility = "hidden";
    errorElem.style.visibility = 'hidden';
  } else {
    // document.getElementById("username-error").textContent = "Invalid username";
    // document.getElementById(errorID).style.visibility = "visible";
    errorElem.style.visibility = 'visible';
  }
}
