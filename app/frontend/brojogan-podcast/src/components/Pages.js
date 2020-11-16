import React, { useEffect, useState, useRef } from 'react';
import Pagination from 'react-bootstrap/Pagination';
import './../css/Pages.css';

function isDigits(str) {
  return str.match(/^\d+$/);
}

// the showItemIndex is implemented quite awkwardly
// to be able to scroll to the item, the Item component will need to accept an id prop
// and set this id as the id of the element. The only id used will be 'scroll-item'.
// maybe should use #id in url thing?
function Pages({ itemDetails, context, itemsPerPage, Item, showItemIndex }) {
  const [pageState, setPageState] = useState();
  const [pageJSX, setPageJSX] = useState();
  // const scrollItemRef = useRef(null);
  const startRef = useRef(null);

  // run once on page load. Create pages array and if showItemIndex is set, set the starting page number and position
  // showItemIndex must be the index of the item you want to show in itemDetails
  useEffect(() => {
    console.log("Pages itemDetails:", itemDetails);
    console.log(itemsPerPage);
    console.log("showItemIndex:", showItemIndex);

    if (itemDetails.length === 0) {
      return;
    }

    let pages = [];
    const numPages = Math.ceil(itemDetails.length / itemsPerPage);
    for (let i = 0; i < numPages + 1; i++) {
      pages.push([]);
    }
    let pgNum = 1, pgIndex = 0
    let startingPageNum = 1, startingScroll = undefined;
    for (let i = 0; i < itemDetails.length; i++, pgIndex++) {
      pages[pgNum][pgIndex] = itemDetails[i];
      if (i === showItemIndex) { // showItemIndex &&
        startingPageNum = pgNum;
        startingScroll = pgIndex;
      }
      if (pgIndex === itemsPerPage - 1) {
        pgNum++;
        pgIndex = -1;
      }
    }
    console.assert(numPages === (pgIndex === 0 ? pgNum - 1 : pgNum));
    setPageState({ pages: pages, lastPage: numPages, pageNum: startingPageNum, scrollIndex: startingScroll });
  }, [ itemDetails, itemsPerPage, context, Item, showItemIndex ]);

  function pageChanged(event) {
    console.log(event.target);
    // React-Bootstrap Pagination is actually pretty bad and makes it awkward to respond to Previous or Next button clicks
    // Maybe should use a different library
    // checking parent as well because if you click directly on the arrow, the event comes on a span, child of the <a>
    let pageNum = undefined;
    if (event.target.id === "prev" || event.target.parentElement.id === "prev") {
      pageNum = pageState.pageNum - 1;
    } else if (event.target.id === "next" || event.target.parentElement.id === "next") {
      pageNum = pageState.pageNum + 1;
    } else if (event.target.text && isDigits(event.target.text)) {
      pageNum = parseInt(event.target.text, 10);
    }
    if (pageNum) {
      console.log({ ...pageState, pageNum: pageNum, scrollIndex: null });
      setPageState({ ...pageState, pageNum: pageNum, scrollIndex: null });
      startRef.current.scrollIntoView({ behavior: 'smooth' });
      // this only works sometimes in Firefox...
    }
  }

  // runs on page change. update displayed pages and page numbers.
  useEffect(() => {
    console.log('pageState useeffect');
    console.log(pageState);
    if (!pageState) {
      return;
    }

    const { pages, lastPage, pageNum, scrollIndex } = pageState;
    console.log(pages);
    console.log(pageNum);

    // manages the page number display
    // there needs to be a way to make big jumps to the middle when there are a lot of pages
    let paginationMiddleItems;
    if (lastPage <= 7) {
      let pages = [2, 3, 4, 5, 6].filter(x => x < lastPage);
      paginationMiddleItems = <React.Fragment>{pages.map(num => <Pagination.Item active={pageNum === num}>{num}</Pagination.Item>)}</React.Fragment>;
    } else {
      let items;
      switch (pageNum) {
        case 1: items = [2, 3, 4]; break;
        case 2: items = [1, 2, 3]; break;
        case 3: items = [0, 1, 2]; break;
        case lastPage - 2: items = [-2, -1, 0]; break;
        case lastPage - 1: items = [-3, -2, -1]; break;
        case lastPage: items = [-4, -3, -2]; break;
        default: items = [-1, 0, 1]; break;
      }

      paginationMiddleItems =
        <React.Fragment>
          {pageNum - 2 <= 2 ? <Pagination.Item active={pageNum === 2}>{2}</Pagination.Item> : <Pagination.Ellipsis />}
          {items.map(change => {
            let num = pageNum + change;
            return <Pagination.Item active={pageNum === num}>{num}</Pagination.Item>
          })}
          {pageNum + 2 >= lastPage - 1 ? <Pagination.Item active={pageNum === lastPage - 1}>{lastPage - 1}</Pagination.Item> : <Pagination.Ellipsis />}
        </React.Fragment>;
    }

    setPageJSX(
      <React.Fragment>
        <div ref={startRef} className="pages"></div> { /* empty div to scroll to top without affecting child selectors */}
        {pages[pageNum].map((item, index) => {
          // onLoad scrolling doesn't work
          if (scrollIndex === index) {
            console.log("scrollIndex matches:", scrollIndex, index);
            return <Item details={item} context={context} id="scroll-item" />
          } else {
            return <Item details={item} context={context} />
          }
        })}
        
        {/* https://github.com/react-bootstrap/react-bootstrap/issues/3281 */}
        {/* Maybe want to allow passing of some 'end' JSX to put before the pagination? */}
        <Pagination onClick={pageChanged}>
          <Pagination.Prev id="prev" disabled={pageNum === 1} />
          <Pagination.Item active={pageNum === 1}>{1}</Pagination.Item>
          {paginationMiddleItems}
          {lastPage !== 1 ? <Pagination.Item active={pageNum === lastPage}>{lastPage}</Pagination.Item> : null}
          <Pagination.Next id="next" disabled={pageNum === lastPage} />
        </Pagination>
      </React.Fragment>
    );
  }, [pageState]);

  useEffect(() => {
    const scrollElem = document.getElementById("scroll-item");
    console.log(scrollElem);
    if (scrollElem) {
      scrollElem.scrollIntoView({ behavior: 'smooth' });
      scrollElem.id = null;
      // don't want to scroll again on every re-render, it's either this or keep more state like firstRender bool
    }
  })

  return (
    // some effects, like Accordian, rely on > css combinators
    // so I can't have any divs or other elements between between the outer content and the pages
    <React.Fragment>
      {pageJSX}
    </React.Fragment>
  )
}

export default Pages;
