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
function PagesFetch({ Item, fetchItems, context }) {
  const [pageState, setPageState] = useState();
  const [error, setError] = useState();
  // const scrollItemRef = useRef(null);
  // const startRef = useRef(null);
  let controller = new AbortController(); // not sure if okay to initialise here

  // todo: prefetch the next page

  // function prefetchPage(pgNum) {
  //   console.log("Prefetching pg", pgNum);
  //   const promise = fetchItems(pgNum).then(({items}) => items);
  //   let pages = [...pageState.pages];
  //   pages[pgNum] = promise;
  //   setPageState({...pageState, pages: pages});
  // }

  function prefetchPage(pgNum) {
    if (typeof (pageState.pages[pgNum]) === 'function') {
      console.log("Prefetching pg", pgNum);
      let pages = [...pageState.pages];
      pages[pgNum] = pages[pgNum].then(x => x); // pages[pgNum] is now a promise
      setPageState({ ...pageState, pages: pages });
    } else {
      console.log("Not prefetching pg", pgNum);
    }
  }


  async function getPage(pgNum) {
    console.log("getPage pageState:", pageState);
    console.log("pages[pgNum]:", pageState.pages[pgNum]);

    let page = pageState.pages[pgNum];
    let pages = [...pageState.pages]; // slow copying?
    if (typeof (page) === 'function') {
      console.log("page is function");
      // pageState.pages[pgNum] stores a function which will create a promise requesting the page
      // resolve promise and get page
      try {
        page = await pageState.pages[pgNum]();
        pages[pgNum] = page;
      } catch (err) {
        setError(err.toString());
        // todo
        return;
      }
    } else {
      // promise has been started or possibly already resolved
      page = await Promise.resolve(page);
    }
    console.log("Gotten page:", page);
    setPageState({ ...pageState, pages: pages, pageNum: pgNum, pageChanging: false });
    prefetchPage(pgNum + 1);
    setError(null);
  }

  // async function getPage(pgNum) {
  //   console.log("getPage pageState:", pageState);
  //   console.log("pages[pgNum]:", pageState.pages[pgNum]);
  //   console.log("Prefetched page before resolve:", prefetchPage);
  //   const prefetchedPage = await Promise.resolve(pageState.pages[pgNum]);
  //   // if a promise has been set, this will resolve it
  //   // if not, and pageState.pages[pgNum] is null, Promise.resolve() will immediately return null
  //   // or if pages[pgNum] is already set to an actual page, it will return the current value
  //   console.log("Prefetched page is:", prefetchedPage);
  //   if (prefetchedPage) {
  //     setPageState({ ...pageState, pageNum: pgNum });
  //   } else {
  //     try {
  //       // const { items: page } = await fetchItems(pgNum, controller.signal);
  //       // don't want to abort because items have been fetched, may as welll save them for if 
  //       const { items: page } = await fetchItems(pgNum);
  //       console.log(page);
  //       let pages = [...pageState.pages];
  //       pages[pgNum] = page;
  //       setPageState({ ...pageState, pages: pages, pageNum: pgNum, pageChanging: false });
  //       prefetchPage(pgNum+1);
  //       setError(null);
  //     } catch (err) {
  //       setError(err.toString());
  //       // throw err; // todo
  //     }
  //   }
  // }

  useEffect(() => {
    async function getPage1() {
      // get page 1, whose response includes the number of pages
      try {
        const { items: page, numPages } = await fetchItems(1);
        console.log(page, numPages);
        let pages = [];
        for (let i = 0; i < numPages; i++) {
          pages.push(() => fetchItems(i).then(({ items }) => items));
        }
        pages[1] = page;
        console.log("pages:", pages);
        console.log(pages, numPages, 1);
        setPageState({ pages: pages, lastPage: numPages, pageNum: 1, pageChanging: false });
        prefetchPage(1);
        setError(null);
      } catch (err) {
        setError(err.toString());
        // throw err; // todo
      }
    }

    console.log("useeffect");
    getPage1();
  }, [fetchItems]);

  // useEffect(() => {
  //   async function getPage1() {
  //     // get page 1, whose response includes the number of pages
  //     try {
  //       const { items: page, numPages } = await fetchItems(1);
  //       console.log(page, numPages);
  //       let pages = [];
  //       for (let i = 0; i < numPages; i++) {
  //         pages.push(null);
  //       }
  //       pages[1] = page;
  //       console.log(pages, numPages, 1);
  //       setPageState({ pages: pages, lastPage: numPages, pageNum: 1, pageChanging: false });
  //       setError(null);
  //     } catch (err) {
  //       setError(err.toString());
  //       // throw err; // todo
  //     }
  //   }

  //   getPage1();
  // }, [fetchItems]);

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
      setPageState({ ...pageState, pageChanging: true })
      getPage(pageNum);
      // startRef.current.scrollIntoView({ behavior: 'smooth' });
      // this only works sometimes in Firefox so removing for consistency
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

  return (
    <React.Fragment>
      <div /*ref={startRef}*/ className="pages"></div>
      {error
        ? <h1>{error}</h1>
        : null
      }

      {pageState && !pageState.pageChanging && pageState.lastPage > 0
        ? pageState.pages[pageState.pageNum].map(item => {
          return <Item details={item} context={context} />
        })
        : (pageState && !pageState.pageChanging && pageState.lastPage === 0
          ? <h1>You have no history</h1>
          : <h1>Loading...</h1>)}

      {pageState && pageState.lastPage > 0
        ? pagination(pageState.pageNum, pageState.lastPage, pageChanged)
        : null}
    </React.Fragment>
  )
}

export default PagesFetch;
