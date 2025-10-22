from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Dict, Iterable, List, Optional, Sequence, Tuple

from psycopg import sql

from app.infrastructure.database import DatabasePool


@dataclass(frozen=True)
class TableSyncConfig:
    source_name: str
    raw_schema: str
    raw_table: str
    primary_keys: Sequence[str]
    incremental_column: Optional[str] = None

    @property
    def raw_identifier(self) -> sql.Identifier:
        return sql.Identifier(self.raw_schema, self.raw_table)


SYNC_STATE_TABLE = sql.Identifier("internal", "sync_state")


class WarehouseRepository:
    """Handle persistence into the analytics warehouse."""

    def __init__(self, pool: DatabasePool) -> None:
        self._pool = pool

    def get_last_incremental_value(self, table: TableSyncConfig) -> Optional[str]:
        if table.incremental_column is None:
            return None

        query = sql.SQL(
            """
            select last_value
            from {sync_state}
            where table_name = %s
            limit 1
            """
        ).format(sync_state=SYNC_STATE_TABLE)

        with self._pool.connection() as conn:
            with conn.cursor() as cur:
                cur.execute(query, (table.source_name,))
                row = cur.fetchone()

        return row[0] if row else None

    def upsert_raw_rows(
        self,
        table: TableSyncConfig,
        rows: List[Dict[str, Any]],
    ) -> Optional[str]:
        """Insert or update rows into the raw schema, returning max incremental value."""

        if not rows:
            return None

        all_columns = self._extract_columns(rows, table.primary_keys)
        column_identifiers = [sql.Identifier(col) for col in all_columns]
        insert_sql = sql.SQL(
            """
            insert into {table} ({columns})
            values ({values})
            on conflict ({conflict_cols})
            do update set {set_clause}
            """
        ).format(
            table=table.raw_identifier,
            columns=sql.SQL(", ").join(column_identifiers),
            values=sql.SQL(", ").join(sql.Placeholder() for _ in all_columns),
            conflict_cols=sql.SQL(", ").join(sql.Identifier(pk) for pk in table.primary_keys),
            set_clause=sql.SQL(", ").join(
                sql.SQL("{col} = excluded.{col}").format(col=sql.Identifier(col))
                for col in all_columns
                if col not in table.primary_keys
            ),
        )

        payload = [self._row_to_tuple(row, all_columns) for row in rows]

        with self._pool.connection() as conn:
            with conn.cursor() as cur:
                cur.executemany(insert_sql, payload)
            conn.commit()

        if table.incremental_column:
            max_value = max(
                (row.get(table.incremental_column) for row in rows if row.get(table.incremental_column)),
                default=None,
            )
            if max_value is None:
                return None

            if hasattr(max_value, "isoformat"):
                return max_value.isoformat()  # type: ignore[no-any-return]

            return str(max_value)

        return None

    def update_incremental_state(
        self,
        table: TableSyncConfig,
        last_value: str,
    ) -> None:
        if table.incremental_column is None or not last_value:
            return

        query = sql.SQL(
            """
            insert into {sync_state} (table_name, last_value)
            values (%s, %s)
            on conflict (table_name)
            do update set last_value = excluded.last_value, updated_at = now()
            """
        ).format(sync_state=SYNC_STATE_TABLE)

        with self._pool.connection() as conn:
            with conn.cursor() as cur:
                cur.execute(query, (table.source_name, last_value))
            conn.commit()

    def run_in_transaction(self, statements: Iterable[str]) -> None:
        with self._pool.connection() as conn:
            with conn.cursor() as cur:
                for statement in statements:
                    cur.execute(statement)
            conn.commit()

    @staticmethod
    def _extract_columns(rows: List[Dict[str, Any]], primary_keys: Sequence[str]) -> List[str]:
        columns = set(primary_keys)
        for row in rows:
            columns.update(row.keys())

        return sorted(columns)

    @staticmethod
    def _row_to_tuple(row: Dict[str, Any], columns: Sequence[str]) -> Tuple[Any, ...]:
        return tuple(row.get(col) for col in columns)
