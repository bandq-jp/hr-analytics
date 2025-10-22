# GCP Project Configuration
project_id = "bandq-dx"

# Container Images
app_image = "gcr.io/bandq-dx/ha-app:dev"

# Database Configuration
database_password           = "bandq_hr_5505bq5505"
metabase_database_password  = "meta_hr_5505bq5505"

# Supabase Configuration
supabase_url                = "https://supabase.com/dashboard/project/icgtokdilecfvguibqfp"
supabase_service_role_key   = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImljZ3Rva2RpbGVjZnZndWlicWZwIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NDcxMDEzOCwiZXhwIjoyMDcwMjg2MTM4fQ.Pk8vCWHvV24tkcFbNX5zZ_x6jv13nQ5JgryvFoTPz6U"

# Dev-specific settings
database_tier               = "db-custom-2-7680"
enable_deletion_protection  = false
vpc_cidr                    = "10.91.0.0/24"
connector_cidr              = "10.9.0.0/28"