-- Metadata used by ingestion jobs.
create table if not exists internal.sync_state (
    table_name text primary key,
    last_value text,
    updated_at timestamptz not null default now()
);
