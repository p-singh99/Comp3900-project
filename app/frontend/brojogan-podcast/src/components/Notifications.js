import React, { useState, useEffect } from 'react'; // useRef
import { Link } from 'react-router-dom';
import { fetchAPI, isLoggedIn } from './../authFunctions';
import './../css/Notifications.css';

let intervalSet = false;
let alreadySeen = [];

function sendSeenFor(notifications) {
    for (let notification of notifications.filter(e => !alreadySeen.includes(e.id))) {
        // add try catch
        fetchAPI(`/users/self/notification/${notification.id}`, 'put', { status: 'read' })
        alreadySeen.push(notification.id);
    }
}

function sendDelete(notification) {
    // add try catch
    fetchAPI(`/users/self/notification/${notification.id}`, 'delete', null)
}

function Notification({ notification, dismissNotification }) {
    return (
        <p>
            {
                notification.status === 'unread' ?
                    <span className="nUnread">• </span>
                    : null
            }
            <Link className={'search-page-link'}
                to={{ pathname: `/podcast/${notification.podcastId}`, state: {} }}
                onClick={e => e.stopPropagation()}>
                {notification.episodeTitle} | {notification.podcastTitle}
            </Link>
            <span className="dismiss-notification" onClick={e => {
                dismissNotification(notification);
                e.stopPropagation();
            }}>×</span>
        </p>
    )

}

function Notifications({ visibility }) {
    const [state, setState] = useState([]);

    useEffect(() => {
        window.setInterval(() => {
            if (isLoggedIn()) {
                console.log("fetching notifications");
                // add try catch
                fetchAPI('/users/self/notifications', 'get', null)
                    .then(newNotifications => {
                        console.log("Setting notifications:");
                        console.log(newNotifications);
                        setState(newNotifications);
                    })
            }
        }, 60000);
    }, []);

    if (!intervalSet) {
        intervalSet = true;
        console.log("setting interval");

        console.log("fetching notifications");
        if (isLoggedIn()) {
            // add catch
            fetchAPI('/users/self/notifications', 'get', null)
                .then(newNotifications => {
                    console.log("Setting notifications:");
                    console.log(newNotifications);
                    setState(newNotifications);
                })
        }
    }

    function dismissNotification(notification) {
        sendDelete(notification);
        let newState = state.filter(i => i.id !== notification.id);
        setState(newState);
    }
    sendSeenFor(state.filter(e => e.status === 'unread'));
    return (
        <React.Fragment>
            <div id="notifications-div" style={{ visibility: visibility ? "visible" : "hidden" }}>
                {
                    state.length === 0 ? <p>No notifications!</p> :
                        state.map(notification => {
                            return <Notification key={notification.id} notification={notification} dismissNotification={dismissNotification} />
                        })
                }
            </div>
        </React.Fragment>
    )
}

export default Notifications;