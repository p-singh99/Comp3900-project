import React, { createRef, useEffect} from 'react';
import { Redirect, BrowserRouter as Router, Route, Switch } from 'react-router-dom';
import './App.css';
import Header from './components/Header';
import NavBar from './components/NavBar';
import Footer from './components/Footer';
import Login from './pages/Login';
import SignUp from './pages/SignUp';
import Search from './pages/SearchPage'
import Home from './pages/Home';
import Description from './pages/Description';
import History from './pages/History';
import Recommended from './pages/Recommended';
import Subscriptions from './pages/Subscriptions';
import About from './pages/About';
import Settings from './pages/Settings'
import { isLoggedIn, checkLogin } from './authFunctions';


function App() {
  const ref = createRef();

  function changePlaying(state) {
    ref.current.updateState(state);
  }

  // on app load, check if token is valid or session has expired
  useEffect(checkLogin, []);

  const defaultComponents = () => (

    <body>
      <div id='main'>
        <Header />
        <div id='middle'>
          <NavBar />
          {/* Routes for all users */}
          <div id="content-div-main">
            <Route path="/" component={Home} exact />
            <Route path="/podcast/:id" exact render={(props) => (<Description {...props} setPlaying={changePlaying} />)}/>
            {/* <Route path="/recommended" component={Recommended} exact /> */}
            <Route path="/about" component={About} exact />
            <Route path="/search" component={Search} />

            {/* Routes for logged in users only */}
            <Route path="/recommended" exact>{isLoggedIn() ? <Recommended /> : <Redirect to="/" />}</Route>
            <Route path="/history" exact>{isLoggedIn() ? <History /> : <Redirect to="/" />}</Route>
            <Route path="/subscriptions" exact >{isLoggedIn() ? <Subscriptions /> : <Redirect to="/" />}</Route>
            <Route path="/settings" exact>{isLoggedIn() ? <Settings /> : <Redirect to="/" />}</Route>
          </div>
        </div>
      </div>
      <footer>
        <Footer ref={ref} />
      </footer>
      {/* move <footer></footer> into Footer component? It breaks it for some reason, makes it overlap with content */}
    </body>

  )
  return (
    <Router>
      <div className="App">
        <Switch>
          {/* There were multiple ways to do the redirect to login, could have just displayed default component without redirect */}
          {/* but that seemed weird, this is more code but makes more sense. */}
          {/* its hard to read though so idk */}
          <Route path="/login" exact>{isLoggedIn() ? <Redirect to="/" /> : <Login />}</Route>
          <Route path="/signup" exact>{isLoggedIn() ? <Redirect to="/" /> : <SignUp />}</Route>
          <Route component={defaultComponents} />
        </Switch>
      </div>
    </Router>
  );
}

export default App;
