import React from 'react';
import {BrowserRouter as Router, Route, Switch} from 'react-router-dom';
import './App.css';
import Header from './components/Header';
import NavBar from './components/NavBar';
import Footer from './components/Footer';
import Login from './pages/Login';
import SignUp from './pages/SignUp';

function App() {
  const defaultComponents = () => (
    <React.Fragment>
      <Header />
      <NavBar />
      <Footer />
    </React.Fragment>
  )
  return (
    <Router>
      <div className="App">
        <Switch>
          <Route path="/login" component={Login} exact />
          <Route path="/signup" component={SignUp} exact/>
          <Route component={defaultComponents}/>
        </Switch>
      </div>
    </Router>
  );
}

export default App;
