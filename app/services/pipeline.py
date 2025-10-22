from __future__ import annotations

import logging
from pathlib import Path
from typing import Dict, Iterable, List

from clients.supabase_client import SupabaseFetcher, SupabaseTableConfig
from config import Settings, get_settings
from infrastructure.database import DatabasePool
from repositories.warehouse import TableSyncConfig, WarehouseRepository

logger = logging.getLogger(__name__)


RAW_TABLES: List[TableSyncConfig] = [
    TableSyncConfig(
        source_name="applicants",
        raw_schema="raw",
        raw_table="applicants",
        primary_keys=("id",),
        incremental_column="updated_at",
    ),
    TableSyncConfig(
        source_name="applications",
        raw_schema="raw",
        raw_table="applications",
        primary_keys=("id",),
        incremental_column="updated_at",
    ),
    TableSyncConfig(
        source_name="application_events",
        raw_schema="raw",
        raw_table="application_events",
        primary_keys=("application_id", "event_type"),
        incremental_column=None,
    ),
    TableSyncConfig(
        source_name="application_notes",
        raw_schema="raw",
        raw_table="application_notes",
        primary_keys=("id",),
        incremental_column="created_at",
    ),
]


class PipelineService:
    def __init__(
        self,
        settings: Settings,
        pool: DatabasePool,
        fetcher: SupabaseFetcher,
        warehouse: WarehouseRepository,
    ) -> None:
        self._settings = settings
        self._pool = pool
        self._fetcher = fetcher
        self._warehouse = warehouse
        self._supabase_configs = {
            table.source_name: SupabaseTableConfig(
                name=table.source_name,
                primary_keys=table.primary_keys,
                incremental_column=table.incremental_column,
            )
            for table in RAW_TABLES
        }

    def run_ingest(self) -> Dict[str, int]:
        """Synchronise Supabase source tables into the raw schema."""

        results: Dict[str, int] = {}
        for table in RAW_TABLES:
            supabase_config = self._supabase_configs[table.source_name]
            last_value = None
            if table.incremental_column and not self._settings.ingest_full_refresh:
                last_value = self._warehouse.get_last_incremental_value(table)

            logger.info(
                "Ingesting table %s (incremental_column=%s, last_value=%s)",
                table.source_name,
                table.incremental_column,
                last_value,
            )

            rows = self._fetcher.fetch_table(supabase_config, last_value)
            logger.info("Fetched %s rows from %s", len(rows), table.source_name)

            max_value = self._warehouse.upsert_raw_rows(table, rows)
            results[table.source_name] = len(rows)

            if max_value:
                self._warehouse.update_incremental_state(table, max_value)

        return results

    def run_transform(self, sql_paths: Iterable[Path]) -> Dict[str, str]:
        """Execute transformation SQL to build staging and mart layers."""

        executed: Dict[str, str] = {}
        statements: List[str] = []
        for path in sql_paths:
            query = path.read_text(encoding="utf-8")
            for statement in self._split_statements(query):
                statements.append(statement)
            executed[str(path)] = "queued"

        if statements:
            self._warehouse.run_in_transaction(statements)
            for path in executed:
                executed[path] = "ok"

        return executed

    def close(self) -> None:
        self._pool.close()

    @staticmethod
    def _split_statements(query: str) -> List[str]:
        statements: List[str] = []
        buffer: List[str] = []
        for line in query.splitlines():
            stripped = line.strip()
            if not stripped or stripped.startswith("--"):
                continue
            buffer.append(line)
            if stripped.endswith(";"):
                statement = "\n".join(buffer).rstrip(";").strip()
                if statement:
                    statements.append(statement)
                buffer = []

        if buffer:
            statement = "\n".join(buffer).strip()
            if statement:
                statements.append(statement)

        return statements


def build_pipeline_service() -> PipelineService:
    settings = get_settings()
    pool = DatabasePool(settings)
    pool.open()
    fetcher = SupabaseFetcher(settings)
    warehouse = WarehouseRepository(pool)
    return PipelineService(settings, pool, fetcher, warehouse)
