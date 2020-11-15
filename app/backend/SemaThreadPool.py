from psycopg2.pool import ThreadedConnectionPool
from threading import Semaphore

class SemaThreadPool(ThreadedConnectionPool):
    def __init__(self, minconn, maxconn, *args, **kwargs):
        self.semaphore = Semaphore(maxconn)
        super().__init__(minconn, maxconn, *args, **kwargs)

    def getconn(self, *args, **kwargs):
        self.semaphore.acquire()
        print(self.semaphore._value)
        return super().getconn(*args, **kwargs)

    def putconn(self, *args, **kwargs):
        super().putconn(*args, **kwargs)
        self.semaphore.release()
