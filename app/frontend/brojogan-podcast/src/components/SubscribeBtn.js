import React, {useState, useEffect} from 'react';
import { fetchAPI } from './../authFunctions';

// Used on Description and Subscriptions pages
// This component does not include styling, only the logic
function SubscribeBtn({ defaultState, podcastID }) {
    const [subscribeBtn, setSubscribeBtn] = useState(defaultState);

    // should like track if a subscribe/unscubscribe request is already in the air before sending another
    // for subscribe button
    function subscribeHandler(podcastID) {
        let body = {};
        body.podcastid = podcastID;
        setSubscribeBtn("...");
        fetchAPI(`/users/self/subscriptions`, 'post', body)
            .then(data => {
                setSubscribeBtn("Unsubscribe");
            })
            .catch(err => {
                setSubscribeBtn("Error");
                console.log(err);
            });
    }

    // for unsubscribe button
    function unSubscribeHandler(podcastId) {
        setSubscribeBtn("...");
        fetchAPI(`/users/self/subscriptions/${podcastId}`, 'delete', null)
            .then(data => {
                setSubscribeBtn("Subscribe");
            })
            .catch(err => {
                setSubscribeBtn("Error");
                console.log(err);
            });
    }

    const handleClickRequest = (event, podcastID) => {
        event.stopPropagation(); // click doesn't bubble up and trigger Card on click, which expands Card
        if (subscribeBtn === 'Unsubscribe') {
            /** User clicked to unsubscribe */
            unSubscribeHandler(podcastID);
        } else {
            /** User clicked to Subscribe */
            subscribeHandler(podcastID);
        }
    }

    useEffect(() => {
        setSubscribeBtn(defaultState);
    }, [defaultState]);

    return (
        <button className="subscribe-btn" onClick={(event) => handleClickRequest(event, podcastID)}>{subscribeBtn}</button>
    )
}

export default SubscribeBtn;
