import React, { useEffect, useState, useRef } from 'react';
import Pagination from 'react-bootstrap/Pagination';
import './../css/Pages.css';

function isDigits(str) {
  return str.match(/^\d+$/);
}

// the showItemIndex is implemented quite awkwardly
// to be able to scroll to the item, the Item component will need to accept an id prop
// and set this id as the id of the element. The only id used will be 'scroll-item'.
// maybe should use #id thing?
function PagesFetch({ Item, fetchItems, numPages, context }) {
  const [pageState, setPageState] = useState();
  // const [pageJSX, setPageJSX] = useState();
  // const scrollItemRef = useRef(null);
  const startRef = useRef(null);
  let controller = new AbortController(); // not sure if okay to initialise here

  async function getPage(pgNum) {
    console.log("getPage pageState:", pageState);
    console.log("pages[pgNum]:", pageState.pages[pgNum]);
    if (pageState.pages[pgNum]) {
      setPageState({ ...pageState, pageNum: pgNum });
    } else {
      try {
        const { items: page } = await fetchItems(pgNum, controller.signal);
        console.log(page);
        let pages = [...pageState.pages];
        pages[pgNum] = page;
        setPageState({ ...pageState, pages: pages, pageNum: pgNum });
      } catch (err) {
        throw err;
      }
    }
  }

  async function getPage0() {
    // get page 0, whose response includes the number of pages
    try {
      // const { items: page, numPages } = await fetchItems(1);
      const { items: page } = await fetchItems(1);
      console.log(page);
      numPages = 2;
      let pages = [];
      for (let i = 0; i < numPages; i++) {
        pages.push(null);
      }
      pages[1] = page;
      console.log(pages, numPages, 1);
      setPageState({ pages: pages, lastPage: numPages, pageNum: 1 });
    } catch (err) {
      throw err;
    }
  }

  // run once on page load.
  useEffect(() => {
    // getPage(0);
    getPage0();
  }, []);

  function pageChanged(event) {
    console.log(event.target);
    controller.abort(); // abort in-air requests from previous page
    controller = new AbortController();
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
      getPage(pageNum);
      startRef.current.scrollIntoView({ behavior: 'smooth' });
      // this only works sometimes in Firefox...
    }
  }

  function pagination(pageNum, lastPage, onPageChange) {
    let paginationMiddleItems;
    if (lastPage <= 7) {
      let pages = [2, 3, 4, 5, 6].filter(x => x < lastPage);
      paginationMiddleItems = <>{pages.map(num => <Pagination.Item active={pageNum === num}>{num}</Pagination.Item>)}</>;
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

    // https://github.com/react-bootstrap/react-bootstrap/issues/3281
    return (
      <Pagination onClick={onPageChange} >
        <Pagination.Prev id="prev" disabled={pageNum === 1} />
        <Pagination.Item active={pageNum === 1}>{1}</Pagination.Item>
        {paginationMiddleItems}
        {lastPage !== 1 ? <Pagination.Item active={pageNum === lastPage}>{lastPage}</Pagination.Item> : null}
        <Pagination.Next id="next" disabled={pageNum === lastPage} />
      </Pagination >
    )
  }

  // runs on page change. update displayed pages and page numbers.
  // useEffect(() => {
  //   console.log('pageState useeffect');
  //   console.log(pageState);
  //   if (!pageState) {
  //     return;
  //   }

  //   const { page, lastPage, pageNum } = pageState;
  //   console.log(page);
  //   console.log(pageNum);

  //   // there needs to be a way to make big jumps to the middle when there are a lot of pages
  //   setPageJSX(
  //     <div ref={startRef} className="pages">
  //       {page.map(item => {
  //         <Item details={item} />
  //       })}
  //       {pagination(pageNum, lastPage, pageChanged)}
  //     </div>
  //   );
  // }, [pageState]);

  return (
    <React.Fragment>
      <div ref={startRef} className="pages">
      </div>
      {pageState
        ? pageState.pages[pageState.pageNum].map(item => {
          return <Item details={item} context={context} />
        })
        : <h1>Loading...</h1>}

      {pageState
        ? pagination(pageState.pageNum, pageState.lastPage, pageChanged)
        : null}
    </React.Fragment>
  )
}

export default PagesFetch;
