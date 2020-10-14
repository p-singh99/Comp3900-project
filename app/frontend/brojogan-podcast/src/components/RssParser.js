import Parser from 'rss-parser';
let parser = new Parser();


function parse_feed(url) {
    let feed = parser.parseURL(url);
    return feed;
}

feed = parse_feed("http://www.hellointernet.fm/podcast?format=rss");
console.log(feed);
