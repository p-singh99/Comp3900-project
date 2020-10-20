import React from 'react';

export default function Search(podcasts) {
    return (
        <div>
            <ul>
                { podcasts.map( p => <li>{ p.title }</li>) }
            </ul>
        </div>
    )
}
