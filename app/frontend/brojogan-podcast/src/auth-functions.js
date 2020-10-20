export const logoutHandler = () => {
  window.localStorage.removeItem('token');
  window.localStorage.removeItem('username');
  window.location.reload();
}

// for when the server unexpectedly returns 401
// token has expired, or user edited it. Don't want to just suddenly refresh and disrupt what they're doing
// should set up token refresh scheme to avoid this.
export const authFailed = () => {
    alert('Your session has expired');
    logoutHandler(); // does this work
}

export const saveToken = (data) => {
  window.localStorage.setItem('token', data.token);
  window.localStorage.setItem('username', data.user);
  // window.localStorage.setItem('exp', data.exp);
}

export const isLoggedIn = () => {
  // if they have a token, consider logged in
  // if the token is invalid, then at some point a request to the backend will return 401
  // and we will delete the token by calling authFailed()
  // that's my current plan for handlign tokens
  return (window.localStorage.getItem("token") !== null)
}
