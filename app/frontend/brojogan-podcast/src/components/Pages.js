import React, { useEffect, useState } from 'react';
import Pagination from 'react-bootstrap/Pagination';

function isDigits(str) {
  return str.match(/^\d+$/);
}

function Pages({ itemDetails, itemsPerPage, Item, showItemIndex }) {
  const [pageState, setPageState] = useState();
  const [pageJSX, setPageJSX] = useState();
  // const [pages, setPages] = useState();
  // const [lastPageNum, setLastPageNum] = useState();

  // might need to put this in [] useEffect
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
      if (pgIndex === itemsPerPage-1) {
        pgNum++;
        pgIndex = -1;
      }
      console.assert(numPages === (pgIndex === 0 ? pgNum-1: pgNum));
    }
    setPageState({ pages: pages, lastPage: numPages, pageNum: startingPageNum, scrollIndex: startingScroll });
  }, []);

  function pageChanged(event) {
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
    setPageJSX(
      <>
        {pages[pageNum].map((item, index) => {
          // pageState.scrollIndex === index
          //   ? <Item details={item} onLoad={(event) => event.target.scrollIntoView({behavior: 'smooth'})}/>
          //   : <Item details={item} />
          // This might work

          // this onLoad scrolling doesn't work
          if (scrollIndex === index) {
            return <Item details={item} onLoad={(event) => { console.log(event); event.target.scrollIntoView({ behavior: 'smooth' })}} />
          } else {
            return <Item details={item} />
          }
        })}
        {/* https://github.com/react-bootstrap/react-bootstrap/issues/3281 */}
        <Pagination onClick={pageChanged}>
          {/* <Pagination.First /> */}
          {/* <Pagination.Prev /> */}
          <Pagination.Item>{1}</Pagination.Item>
          <Pagination.Ellipsis />
          <Pagination.Item>{pageNum - 2}</Pagination.Item>
          <Pagination.Item>{pageNum - 1}</Pagination.Item>
          <Pagination.Item active>{pageNum}</Pagination.Item>
          <Pagination.Item>{pageNum + 1}</Pagination.Item>
          <Pagination.Item>{pageNum + 2}</Pagination.Item>
          <Pagination.Ellipsis />
          <Pagination.Item>{lastPage}</Pagination.Item>
          {/* <Pagination.Next /> */}
          {/* <Pagination.Last /> */}
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
