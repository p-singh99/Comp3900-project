# Ultracast
## COMP3900-H13A-BroJogan 
### Justin Mack (z5160822), Pawanjot Singh (zXXXXXXX), Michael Corbin (z5206453), Nicholas Bang (z5162078), Tom Bowden (z5161185)

### Roles
Scrum Master: Nicholas  
Developers: Justin, Pawanjot, Michael, Tom 

### Table of Contents
1...XXXX  
2...XXXX

### Submission Date
dd/mm/yyyy

---------------------

## Background

### Problem Being Solved

Listening to podcasts is popular with many people. We aim to make listening to podcasts easier for people who wish to use their desktop or laptop computers for listening to podcasts.  
Many solutions for listening to podcasts exist, notably Spotify, Pocketcasts, the ABC Listen App, Google Podcasts, and Soundcloud. Each of these have a number of strength as well as drawbacks.  
Many of the podcast solutions require users to sign up to their platform before users can listen to podcasts. We aim to allow users to be able to access their podcasts without having to sign in, however we also aim to offer account functionality so the user's place in podcasts and tastes in podcasts can be tracked.  
We also aim to offer users the ability to access podcasts on a web app, since many of the other solutions listed below are for mobile only, or focus more on mobile.  

Finally we aim to provide users with all of the information available about the podcasts they listen to such as descriptions and show notes.

### Spotify
Spotify is available primarily as a phone app, as well as a desktop applications, and a web app. It requires users sign up to the app, and offers podcasts as a secondary feature to its core use; music.  

#### Drawbacks

* Spotify requires users to sign up
* Spotify shows ads to non-premium users (users who do not pay for the service)
* Spotify does not support show notes
* Spotify's download system is proprietry meaning users have to use their app to listen to their downloaded podcasts
* On the desktop and web apps, users cannot download podcasts

### Pocketcasts
Pocketcasts is primarily a phone app that is dedicated to podcasts.

#### Drawbacks

* Pocketcasts requires users to sign up before they can access the platform
* Pocketcasts restricts use of their web app to paying customers

### ABC Listen App
The ABC Listen App is a mobile app that allows users to listen to ABC produced radio shows and podcasts.

#### Drawbacks

* The ABC Listen app only provides access to ABC radio programs and podcasts
* The ABC listen app is mobile only and does not allow desktop users to access their service

### Google Podcasts

Google Podcasts is a web app and mobile app that is dedicated to podcasts.

#### Drawbacks

* Google Podcasts does not allow access to the show notes of each episode
* The Google Podcasts web app does not allow users to download episodes

### Soundcloud

#### Drawbacks

* Soundcloud has very spotty coverage of podcast apps, and does not support RSS feeds which are the standard for distributing podcasts

---------------------

## User Stories & Sprints

### User stories

### Sprint timeline
| Sprint # / Event |  Week | Dates |
|------------------|-------|-------|---------------------|--------------|
| 1             | 3-5 | Thu Oct 1 - Wed Oct 14  | 
| Demo          | 5   | Thu Oct 15              |
| 2             | 5-7 | Thu Oct 15 - Wed Oct 28 |
| Retrospective | 7   | Thu Oct 29              |
| 3             | 7-9 | Thu Oct 29 - Wed Nov 11 |
| Demo          | 8   | Thu Nov 5               |
| Retrospective | 9   | Thu Nov 12              |
| Submission    | 10  | Mon Nov 16              |


### First sprint user stories
**Podcast searching:**  
CHB-14: As a listener, I want to be able to search for a podcast so that I can find the right podcast to listen to. (BASIC VERSION)  
CHB-19: As a listener, I want to be able to see the title of relevant podcasts and the number of subscribers so I can find the most popular podcast.  
CHB-23: As a listener, I want to be able to select a specific podcast from the list shown to view its full details so that I can decide if It's right for me.  

! These user stories would mean that login was implemented in the first sprint without actually being of any use to users, that might be bad?  
**User authorisation:**  
CHB-33: As a listener, I want to be able to log in so that I can access my account, and others cannot.  
CHB-34: As a listener, I want to be able to create an account so that my preferences and history can be stored for me.  
CHB-35: As a listener, I want to be able to log out so that other computer users can't access my account, and I can use the website as another user.  

**Podcast download:**  
CHB-20: As a listener, I want to be able to download podcasts for offline listening.  

### Project objectives
> "Clearly communicates how all project objectives are satisfied by user stories that are defined." 

! I think this is implicit in the previous sections?

### Novel functionality
Given our analysis of existing services above, we highlight the following features as novel functionality:
- Ability to browse the entire website and access, play and download any podcast without an account
  * ! can this really be reflected as a user story?
- Display show notes during podcast play
  * ! add a user story for this?
- Ability to view user-submitted timestamps during podcast play
  * ! add a user story for this?
- Podcast episodes can be downloaded (including batch downloading) in MP3 form: CHB-36

---------------------

## Interface & Flow Diagrams

---------------------

## System Architecture
Presentation layer:   
The frontend code which creates the user interface in the user's web browser, by running in the end-user's browser. This code interacts with the backend APIs by sending requests such as search queries, requests for a particular podcast's details, and music files for a particular podcast episode. The frontend code then interprets the data in these responses to decide on interface changes and display messages, formats the data to display within the interface, and plays the music if relevant.
- Technologies: HTML, CSS, React JS.

Business layer:  RESTful API something something.

API structure:
GET endpoint.com/api/podcast/\<podcastID>/details
| HTTP Method |  Endpoint | Action |
|--------0----|-----------|-----------------|
| 1             | 3-5 | Thu Oct 1 - Wed Oct 14  | 
| Demo          | 5   | Thu Oct 15              |
| 2             | 5-7 | Thu Oct 15 - Wed Oct 28 |
| Retrospective | 7   | Thu Oct 29              |
| 3             | 7-9 | Thu Oct 29 - Wed Nov 11 |
| Demo          | 8   | Thu Nov 5               |
| Retrospective | 9   | Thu Nov 12              |
| Submission    | 10  | Mon Nov 16              |

- Technologies: Python/Flask

Data layer:  

- Technologies: PostgreSQL

### External actors / user types
- Listeners: Listeners want to find, browse, discover, listen to, download and rate podcasts. Subscriptions make it easier for them to keep track of their podcasts.
- Podcast owners: Podcast owners want to add their podcast to the database, and monitor listener numbers and ratings.
- ?

frontend: react/javascript?
backend: python, flask, PostgreSQL
ER diagram

