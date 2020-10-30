import React, { useEffect, useState } from 'react';
import Pagination from 'react-bootstrap/Pagination';

function isDigits(str) {
  return str.match(/^\d+$/);
}

function Pages({ itemDetails, itemsPerPage, Item, showItemIndex }) {
  const [pageState, setPageState] = useState();
  const [pageJSX, setPageJSX] = useState();

  // run once on page load. Create pages array and if showItemIndex is set, set the starting page number and position
  useEffect(() => {
    console.log(itemDetails);
    console.log(itemsPerPage);

    let pages = [];
    const numPages = Math.ceil(itemDetails.length / itemsPerPage);
    for (let i = 0; i < numPages + 1; i++) {
      pages.push([]);
    }
    let pgNum = 1, pgIndex = 0
    let startingPageNum = 1, startingScroll = undefined;
    for (let i = 0; i < itemDetails.length; i++, pgIndex++) {
      pages[pgNum][pgIndex] = itemDetails[i];
      if (showItemIndex && i === showItemIndex) {
        startingPageNum = pgNum;
        startingScroll = pgIndex;
      }
      if (pgIndex === itemsPerPage - 1) {
        pgNum++;
        pgIndex = -1;
      }
      console.assert(numPages === (pgIndex === 0 ? pgNum - 1 : pgNum));
    }
    setPageState({ pages: pages, lastPage: numPages, pageNum: startingPageNum, scrollIndex: startingScroll });
  }, []);

  function pageChanged(event) {
    console.log(event.target);
    if (event.target.text && isDigits(event.target.text)) {
      let pageNum = parseInt(event.target.text, 10);
      console.log({ ...pageState, pageNum: pageNum });
      setPageState({ ...pageState, pageNum: pageNum });
    }
  }

  useEffect(() => {
    console.log('pageState useeffect');
    console.log(pageState);
    if (!pageState) {
      return;
    }

    const { pages, lastPage, pageNum, scrollIndex } = pageState;
    console.log(pages);
    console.log(pageNum);

    let paginationMiddleItems;
    if (lastPage <= 7) {
      paginationMiddleItems = <>{[2, 3, 4, 5, 6].map(num => <Pagination.Item active={pageNum === num}>{num}</Pagination.Item>)}</>;
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
        <>
          {pageNum - 2 <= 2 ? <Pagination.Item active={pageNum === 2}>{2}</Pagination.Item> : <Pagination.Ellipsis />}
          {items.map(change => {
            let num = pageNum + change;
            return <Pagination.Item active={pageNum === num}>{num}</Pagination.Item>
          })}
          {pageNum + 2 >= lastPage - 1 ? <Pagination.Item active={pageNum === lastPage - 1}>{lastPage - 1}</Pagination.Item> : <Pagination.Ellipsis />}
        </>;
    }

    setPageJSX(
      <>
        {pages[pageNum].map((item, index) => {
          // pageState.scrollIndex === index
          //   ? <Item details={item} onLoad={(event) => event.target.scrollIntoView({behavior: 'smooth'})}/>
          //   : <Item details={item} />

          // this onLoad scrolling doesn't work
          if (scrollIndex === index) {
            return <Item details={item} onRender={(event) => { console.log(event); event.target.scrollIntoView({ behavior: 'smooth' }) }} />
          } else {
            return <Item details={item} />
          }
        })}
        {/* https://github.com/react-bootstrap/react-bootstrap/issues/3281 */}
        <Pagination onClick={pageChanged}>
          <Pagination.Prev disabled={pageNum === 1} />
          <Pagination.Item active={pageNum === 1}>{1}</Pagination.Item>
          {paginationMiddleItems}
          {lastPage !== 1 ? <Pagination.Item active={pageNum === lastPage}>{lastPage}</Pagination.Item> : null}
          <Pagination.Next disabled={pageNum === lastPage} />
        </Pagination>
      </>
    );
    // if (pageState.scrollIndex) {
    //   // scroll somehow
    // }
  }, [pageState]);

  return (
    <div>
      {pageJSX}
    </div>
  )
}

export default Pages;
