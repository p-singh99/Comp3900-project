import React, { useEffect, useState/*, useRef*/ } from 'react';
import Pagination from 'react-bootstrap/Pagination';
import './../css/Pages.css';

function isDigits(str) {
  return str.match(/^\d+$/);
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

function PagesFetch({ Item, fetchItems, context }) {
  const [pageState, setPageState] = useState();
  const [error, setError] = useState();
  // const startRef = useRef(null);

  async function getPage(pgNum) {
    let page = pageState.pages[pgNum];
    let pages = [...pageState.pages]; // slow copying?
    if (!page) { // fetching hasn't been started
      page = fetchItems(pgNum).then(({ items }) => items);
    }
    try {
      page = await Promise.resolve(page); // now page is the actual page object, which next time will Promise.resolve() to itself
    } catch (err) {
      setError(err.toString());
      // todo
      return;
    }

    pages[pgNum] = page;
    console.log("Gotten page:", page);
    setPageState({ ...pageState, pages: pages, pageNum: pgNum, pageChanging: false });
    setError(null);
  }

  useEffect(() => {
    async function getPage1() {
      // get page 1, whose response includes the number of pages
      try {
        const { items: page, numPages } = await fetchItems(1);
        console.log("getPage1:", page, numPages);
        let pages = [];
        for (let i = 0; i <= numPages; i++) { // page numbers start at 1
          pages.push(null);
        }
        pages[1] = page;
        console.log("pages:", pages);
        setPageState({ pages: pages, lastPage: numPages, pageNum: 1, pageChanging: false });
        setError(null);
      } catch (err) {
        setError(err.toString());
        // throw err; // todo
      }
    }

    getPage1();
  }, [fetchItems]);

  // when page state has finished changing, prefetch the next page
  useEffect(() => {
    const prefetchPage = (pgNum) => {
      if (!pageState.pages[pgNum]) {
        console.log("Prefetching pg", pgNum);
        let pages = [...pageState.pages];
        pages[pgNum] = fetchItems(pgNum).then(({ items }) => items); // pages[pgNum] is now a promise
        setPageState({ ...pageState, pages: pages });
      } else {
        // page already fetched or fetching
        console.log("Not prefetching pg", pgNum);
      }
    }

    if (pageState && pageState.pageNum < pageState.lastPage) {
      console.log("pageState useeffect");
      prefetchPage(pageState.pageNum + 1);
    }
  }, [pageState]) // ofc linter wants fetchItems in this dependency array but its a bit weird

  // handler for page changed in page number zone
  function pageChanged(event) {
    console.log(event.target);
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

  return (
    <React.Fragment>
      <div /*ref={startRef}*/ className="pages"></div>
      {error
        ? <h1>{error}</h1>
        : null
      }

      { pageState && !pageState.pageChanging && pageState.lastPage > 0
        ? pageState.pages[pageState.pageNum].map(item => {
          return <Item details={item} context={context} />
        })
        : (pageState && !pageState.pageChanging && pageState.lastPage === 0
          ? <h1>You have no history</h1>
          : <h4>Loading...</h4>)
      }

      {pageState && pageState.lastPage > 0
        ? pagination(pageState.pageNum, pageState.lastPage, pageChanged)
        : null}
    </React.Fragment>
  )
}

export default PagesFetch;
