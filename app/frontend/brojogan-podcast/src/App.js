import React, { useState } from 'react';
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
import { isLoggedIn } from './auth-functions';

function App() {
  // on app load, check if token valid using useeffect?

  const [playing, setPlaying] = useState({
    title: "No Podcast Playing",
    podcastTitle: "",
    src: "",
    thumb: "",
    guid: "",
    podcastID: "",
    progress: 0.0
  });
  function changePlaying(state) {
    console.log("new state is");
    console.log(state);
    setPlaying(state);
  }

  const defaultComponents = () => (

    <body>
      <div id='main'>
        <Header />
        <div id='middle'>
          <NavBar />
          <Route path="/" component={Home} exact />
          <Route path="/history" component={History} exact />
          <Route path="/podcast/:id" exact render={(props) => (<Description {...props} setPlaying={changePlaying} />)}/>
          <Route path="/recommended" component={Recommended} exact />
          <Route path="/subscriptions" component={Subscriptions} exact />
          <Route path="/about" component={About} exact />
          <Route path="/search" component={Search} exact />
          {/* <Route path="/description" component={() => <Description />} exact /> */}
        </div>
      </div>
      <footer>
        <Footer state={playing} setState={changePlaying} />
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
