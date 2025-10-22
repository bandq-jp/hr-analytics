from __future__ import annotations

from typing import Any, Dict, Iterable, List, Optional

import httpx
from supabase import Client, create_client

from app.config import Settings


class SupabaseTableConfig:
    """Configuration for table-level sync behaviour."""

    def __init__(
        self,
        name: str,
        primary_keys: Iterable[str],
        incremental_column: Optional[str] = None,
    ) -> None:
        self.name = name
        self.primary_keys = tuple(primary_keys)
        self.incremental_column = incremental_column


class SupabaseFetcher:
    """Thin wrapper over supabase-py that handles pagination and retries."""

    def __init__(self, settings: Settings, timeout: float = 10.0) -> None:
        self._settings = settings
        self._client: Client = create_client(
            supabase_url=str(settings.supabase_url),
            supabase_key=settings.supabase_key,
        )
        self._batch_size = settings.sync_batch_size

    def fetch_table(
        self,
        table: SupabaseTableConfig,
        last_value: Optional[str] = None,
    ) -> List[Dict[str, Any]]:
        """Fetch rows from Supabase with optional incremental filter.

        Args:
            table: Table metadata.
            last_value: ISO8601 string used to filter rows >= last_value on incremental column.
        """

        range_from = 0
        payload: List[Dict[str, Any]] = []

        while True:
            query = (
                self._client.table(table.name)
                .select("*")
                .range(range_from, range_from + self._batch_size - 1)
            )

            if table.incremental_column and last_value:
                query = query.gte(table.incremental_column, last_value)

            if table.incremental_column:
                query = query.order(table.incremental_column, desc=False)

            response = query.execute()
            rows = response.data or []
            payload.extend(rows)

            if len(rows) < self._batch_size:
                break

            range_from += self._batch_size

        return payload

    def healthcheck(self) -> Dict[str, Any]:
        """Perform a lightweight request to validate connectivity."""

        try:
            self._client.table("applicants").select("id").limit(1).execute()
        except httpx.HTTPError as exc:  # pragma: no cover
            raise RuntimeError("Failed to reach Supabase") from exc

        return {"status": "ok"}
