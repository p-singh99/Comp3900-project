import Parser from 'rss-parser';
let parser = new Parser();


function parse_feed(url) {
    let feed = parser.parseURL(url);
    return feed;
}

parse_feed("http://podcasts.joerogan.net/feed").then((feed) => {
    console.log(feed);
});
