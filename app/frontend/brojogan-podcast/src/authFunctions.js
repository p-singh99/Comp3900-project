import { API_URL } from './constants';

export const logoutHandler = () => {
  window.localStorage.removeItem('token');
  window.localStorage.removeItem('username');
  window.location.reload();
}

// for when the server unexpectedly returns 401
// token has expired, or user edited it. Don't want to just suddenly refresh and disrupt what they're doing
// should set up token refresh scheme to avoid this.
export const authFailed = () => {
    if (isLoggedIn()) { // lazy way to deal with this being called twice - only run it the first time
      alert('Your session has expired');
      logoutHandler();
    }
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
  // that's my current plan for handling tokens
  return (window.localStorage.getItem("token") !== null)
}

export const getUsername = () => {
  return window.localStorage.getItem("username");
}

export const getToken = () => {
  return window.localStorage.getItem("token");
}

export function checkLogin() {
  console.log("Checking login");
  if (isLoggedIn()) {
    fetchAPI("/protected");
  }
}

// failAuth = true means that if response is 401, it will assume the token has expired and force re-login
// if failAuth = false, it will just return that authentication failed
// returns resp.json() or an error
// give endpoint as eg /podcasts/4
// sends json. provide body as js object
// signal: const controller = new AbortController(); fetchAPI(..., controller.signal); controller.abort()
// this needs try catch around it
export async function fetchAPI(endpoint, method='get', body=null, signal=null) {
  console.log("fetchAPI:", endpoint);
  let resp, data;
  let args = {method: method, headers: {'token': getToken()}};
  if (body) {
    args.body = JSON.stringify(body);
    args.headers["Content-Type"] = "application/json";
  }
  if (signal) {
    args.signal = signal;
  }
  console.log(args);
  
  try {
    resp = await fetch(`${API_URL}${endpoint}`, args);
    data = await resp.json();
  } catch (error) {
    throw error;
  }
  if (resp.ok) {
    return data;
  } else if (resp.status === 401) {
    if (data.error && data.error.toLowerCase().includes("token")) {
      authFailed(); // doesn't return
    }
    throw Error(data.error || "Authentication failed");
  } else if (resp.status === 404) {
    throw Error("404 Not Found"); // stupid
  } else {
    throw Error(data.error);
  }
}
