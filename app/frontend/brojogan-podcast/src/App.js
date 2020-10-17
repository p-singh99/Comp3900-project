import React from 'react';
import {BrowserRouter as Router, Route, Switch} from 'react-router-dom';
import './App.css';
import Header from './components/Header';
import NavBar from './components/NavBar';
import Footer from './components/Footer';
import Login from './pages/Login';
import SignUp from './pages/SignUp';
import Home from './pages/Home';
import Description from './pages/Description';
import History from './pages/History';
import Recommended from './pages/Recommended';
import Subscriptions from './pages/Subscriptions';
import About from './pages/About';

function App() {
  // on app load, check if token valid using useeffect?

  const defaultComponents = () => (
    <div id='main'>
      <Header />
      <div id='middle'>
        <NavBar />
        <Route path="/" component={Home} exact />
        <Route path="/history" component={History} exact />
        <Route path="/podcast/:id" component={Description} exact/>
        {/* <Route path="/podcast/:id" exact render={(props) => (<Description {...props} url={'https://podcastfeeds.nbcnews.com/nbc-nightly-news'} />)}/> */}
        <Route path="/recommended" component={Recommended} exact />
        <Route path="/subscriptions" component={Subscriptions} exact />
        <Route path="/about" component={About} exact />
        {/* <Route path="/description" component={() => <Description />} exact /> */}
      </div>    
      <Footer />
    </div>
  )
  return (
    <Router>
      <div className="App">
        <Switch>
          <Route path="/login" component={Login} exact /> { /* if user is logged in, route to default? */}
          <Route path="/signup" component={SignUp} exact/>
          <Route component={defaultComponents}/>
        </Switch>
      </div>
    </Router>
  );
}

export default App;
