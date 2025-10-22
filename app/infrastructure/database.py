from __future__ import annotations

from contextlib import contextmanager
from typing import Iterator, Optional

from psycopg_pool import ConnectionPool

from config import Settings


class DatabasePool:
    """Lazy-initialised connection pool for Cloud SQL / PostgreSQL."""

    def __init__(self, settings: Settings) -> None:
        self._conninfo = settings.database_url
        self._pool: Optional[ConnectionPool] = None

    def open(self) -> None:
        if self._pool is None:
            self._pool = ConnectionPool(
                conninfo=self._conninfo,
                min_size=1,
                max_size=5,
                kwargs={"autocommit": False},
            )

    def close(self) -> None:
        if self._pool is not None:
            self._pool.close()
            self._pool = None

    @contextmanager
    def connection(self) -> Iterator:
        if self._pool is None:
            raise RuntimeError("Database pool is not initialised. Call open() first.")

        with self._pool.connection() as conn:
            yield conn

