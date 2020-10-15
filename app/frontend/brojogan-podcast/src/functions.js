function logoutHandler() {
    window.localStorage.removeItem('token');
    window.location.reload();
    // reload page?
}
