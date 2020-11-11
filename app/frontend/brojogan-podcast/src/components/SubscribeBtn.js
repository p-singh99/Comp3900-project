import React, {useState} from 'react';
import { fetchAPI } from './../auth-functions';

function SubscribeBtn({ defaultState, podcastID }) {
    const [subscribeBtn, setSubscribeBtn] = useState(defaultState);

    // should like track if a subscribe/unscubscribe request is already in the air before sending another
    function subscribeHandler(podcastID) {
        console.log("entered into subhandler");
        console.log(podcastID);
        let body = {};
        body.podcastid = podcastID;
        setSubscribeBtn("...");
        fetchAPI(`/podcasts/${podcastID}`, 'post', body)
            .then(data => {
                setSubscribeBtn("Unsubscribe");
            })
    }

    // unsubscription button
    function unSubscribeHandler(podcastID) {
        console.log("entered into Unsubhandler");
        console.log(podcastID);
        let body = {};
        body.podcastid = podcastID;
        setSubscribeBtn("...");
        fetchAPI(`/podcasts/${podcastID}`, 'delete', body)
            .then(data => {
                setSubscribeBtn("Subscribe");
            })
    }

    const handleClickRequest = (event, podcastID) => {
        event.stopPropagation();
        if (subscribeBtn === 'Unsubscribe') {
            /** User clicked to unsubscribe */
            unSubscribeHandler(podcastID);
        } else {
            /** User clicked to Subscribe */
            subscribeHandler(podcastID);
        }
    }

    return (
        <button className="subscribe-btn" onClick={(event) => handleClickRequest(event, podcastID)}>{subscribeBtn}</button>
    )
}

export default SubscribeBtn;
