// Example podcast: https://podcastfeeds.nbcnews.com/nbc-nightly-news

// function Podcast() {
//   // set elements which do not require values
//   this.description = "";
//   this.copyright = "";
//   this["itunes-owner"] = "";
//   this["itunes-author"] = "";
//   this["language"] = "";
//   this["itunes:category"] = "";
//   // ...
// }

function verifyPodcast(podcast) {
  if (podcast["title"] === undefined) {
    return false;
  }
  return true;
}
// todo handle dodgy feeds

// wrap this in a try catch always...
export function getPodcastFromXML(xmlText) {
  const parser = new DOMParser();
  const xml = parser.parseFromString(xmlText, "text/xml");
  let podcast = {};
  let channel = xml.getElementsByTagName("channel")[0];
  console.log(channel);
  podcast = getDetailsFromChannel(channel);
  podcast["episodes"] = getEpisodesFromChannel(channel);
  if (!verifyPodcast(podcast)) {
    return null;
  }
  return podcast;
}

function getChildrenByTagName(node, tag) {
  let children = [];
  for (let child of node.childNodes) { // use node.children not node.childNodes
      if (child.nodeName === tag) {
          children.push(child);
      }
  }
  // return node.childNodes.filter(child => child.nodeName === tag); // test this
  return children;
}

// extract out common features of podcast and episode?

// returns object with fields 
// "title", "description", "copyright", "author", "language", "categories" (list), "explicit" (bool), "keywords" (list), "image"
function getDetailsFromChannel(channel) {
  let podcast = {};
  for (let node of channel.children) {
      switch (node.nodeName.toLowerCase()) {
          case "title": podcast["title"] = node.textContent; break;
          case "description": podcast["description"] = node.textContent; break;
          // case "managingEditor": podcast["managingEditor"] = node.textContent; break;
          case "copyright": podcast["copyright"] = node.textContent; break;
          case "itunes:owner":
              // slightly complicated, not important
              break;
          case "itunes:author": podcast["author"] = node.textContent; break;
          case "language": 
              podcast["language"] = node.textContent;
              // maybe convert?
              break;
          case "itunes:category":
              // todo
              break;
          case "itunes:explicit": podcast["explicit"] = getExplicitBool(node); break;
          case "itunes:keywords": podcast["keywords"] = node.textContent.split(","); break;
          case "itunes:image": podcast["image"] = node.attributes["href"].textContent; break;
          case "itunes:summary":
              if (! podcast["description"]) {
                  podcast["description"] = node.textContent;
              }
              break;
          case "link": podcast["link"] = node.textContent; break;
          default: break;
          // others: generator, atom:link, itunes:new-feed-url (for when feeds are changed - do later), itunes:type, itunes:episode, itunes: season, itunes:episodeType, ...
      }
  }
  return podcast;
}

function getExplicitBool(node) {
  let lc = node.textContent.toLowerCase();
  if (lc === "true" || lc === "yes") {
      return true;
  } else {
      return false;
  }
}

// function verifyEpisode(episode) {
//   if (episode["title"] === undefined 
//     || episode["guid"] === undefined
//     || episode["url"] === undefined 
//     || episode["timestamp"] === undefined) {
//     return false;
//   }
//   return true;
// }

function isDigits(str) {
    return str.match(/^\d+$/);
}

// returns list of objects with fields 
// "title", "description", "guid", "image", "keywords" (list), "duration", "url", "bytes" (integer), "type", "timestamp" (unix timestamp), "explicit" (bool)
function getEpisodesFromChannel(channel) {
let episodes = [];
let episodeNodes = getChildrenByTagName(channel, "item");
for (let item of episodeNodes) {
  let episode = {};
  for (let node of item.children) {
          switch (node.nodeName.toLowerCase()) {
              case "title": episode["title"] = node.textContent; break;
              case "description": episode["description"] = node.textContent.trim(); break;
              case "guid": episode["guid"] = node.textContent; break;
              case "itunes:image": episode["image"] = node.attributes["href"].textContent; break;
              case "itunes:keywords": episode["keywords"] = node.textContent.split(","); break;
              case "itunes:duration": // need to convert duration to common format - it may be seconds or something like "00:09:12" (hh:mm:ss)
                  if (isDigits(node.textContent)) { // by the specification, if this is the case then the field should be seconds
                    // the provided duration seconds seem to frequently be wrong though
                    // console.log(episode.title);
                    // console.log(node.textContent);
                    episode["durationSeconds"] = parseInt(node.textContent, 10);
                    let hhmmss = new Date(node.textContent*1000).toISOString().substr(11,8);
                    // console.log(hhmmss);
                    if (hhmmss.startsWith("00:")) {
                      hhmmss = hhmmss.substr(3);
                    } else if (hhmmss.startsWith("0")) {
                      hhmmss = hhmmss.substr(1);
                    }
                    episode["duration"] = hhmmss;
                  } else {
                    // assuming that duration is in hh:mm:ss form
                    episode["duration"] = node.textContent;
                    const smh = episode["duration"].split(":").map(x => parseInt(x, 10)).reverse();
                    let seconds = 0;
                    for (let i in smh) {
                      seconds += smh[i]*(60**i);
                    }
                    // let seconds = hms[hms.length-1] + hms[hms.length-2]*60 + hms[hms.length-3]*60*60;
                    // console.log("seconds:", seconds);
                    episode["durationSeconds"] = seconds;
                  }
                  break;
              case "enclosure": 
                  for (let attr of node.attributes) {
                      if (attr.nodeName.toLowerCase() === "url") {
                          episode["url"] = attr.textContent;
                      } else if (attr.nodeName.toLowerCase() === "length") {
                          episode["bytes"] = parseInt(attr.textContent, 10);
                      } else if (attr.nodeName.toLowerCase() === "type") {
                          episode["type"] = attr.textContent; // change to constants / standardised?
                      }
                      // length clashes with the js property length, so can't access it with child.attributes["length"];
                  }
                  break;
              case "pubdate": episode["timestamp"] = new Date(node.textContent).getTime(); break;
              case "itunes:explicit": episode["explicit"] = getExplicitBool(node); break;
              case "itunes:title":
                  if (! episode["title"]) {
                      episode["title"] = node.textContent;
                  }
                  break;
              case "itunes:summary":
                  if (! episode["description"]) {
                      episode["description"] = node.textContent;
                  }
                  break;
              case "link": episode["link"] = node.textContent; break;
              default: break;
          }
          // there is one more: content:encoded
      }
      episodes.push(episode);
  }
  episodes.sort(compareEpisodes); // is this actually necessary? The rss feed creators have their own order and its normal (always?) the same as this
  return episodes;
}

// a comes first -> return < 0
// b comes first -> return > 0
// return = 0 not always supported
function compareEpisodes(a, b) {
  if (!b["timestamp"] || !a["timestamp"]) {
    return 1;
  }
  return b["timestamp"] - a["timestamp"];
}
