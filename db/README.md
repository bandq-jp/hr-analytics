# Database Setup

1. Initialise schemas and base tables:
   ```bash
   psql "$DATABASE_URL" -f db/sql/init/00_schemas.sql
   psql "$DATABASE_URL" -f db/sql/init/10_raw_tables.sql
   psql "$DATABASE_URL" -f db/sql/init/20_internal_tables.sql
   ```
2. Deploy transformation views (these are idempotent and safe to rerun):
   ```bash
   psql "$DATABASE_URL" -f db/sql/transform/10_stg_views.sql
   psql "$DATABASE_URL" -f db/sql/transform/20_mart_views.sql
   ```
