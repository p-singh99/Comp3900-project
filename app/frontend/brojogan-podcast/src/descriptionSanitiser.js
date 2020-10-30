function onTag(tag, html, options) {
  if (tag === 'p') {
    return '<br>'; // p tags screw up the div onClick, this is easier
  }
  // no return, it does default
}

// this will make sure that all rels are nofollow, but it won't add nofollow to links
function onIgnoreTagAttr(tag, name, value, isWhiteAttr) {
  if (tag === 'a' && name === 'rel') {
    return 'rel=nofollow'; // why does this work? Shouldn't I just return nofollow?
  } else if (tag === 'a' && name === 'target') {
    return 'target=_blank;'
  }
  // no return, it does default ie remove attibute
}

// maybe use DOMPurify instead, and should try to add rel="nofollow" to links
// also should set target = _blank on all links
// could also do that in js - get all links and loop through setting the attributes
// or could set base target = _blank, and then change it on the ones we control
// this doesn't really feel secure, this third party script could get bugs or be altered
// should put the script in local folder
export function sanitiseDescription(description) {
  // https://www.npmjs.com/package/xss
  // https://jsxss.com/en/options.
  let options = {
    whiteList: {
      a: ['href'], // title
      // p: [],
      // strong: []
    },
    stripIgnoreTag: true,
    onTag: onTag,
    onIgnoreTagAttr: onIgnoreTagAttr
  };
  description = window.filterXSS(description, options);
  return description;
}

// https://stackoverflow.com/questions/1912501/unescape-html-entities-in-javascript
function htmlDecode(text) {
  let doc = new DOMParser().parseFromString(text, "text/html");
  return doc.documentElement.textContent;
}

// this function is for removing tags so they don't show up in text
// it is not for security sanitisting for innerHTML
export function unTagDescription(description) {
  description = description.replace(/<[^>]+>/g, ''); // remove HTML tags - could be flawed
  description = htmlDecode(description);
  return description;
}
