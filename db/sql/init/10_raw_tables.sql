-- Mirror of Supabase source tables with relaxed typing for ingestion.
create table if not exists raw.applicants (
    id uuid primary key,
    applicant_name text not null,
    sex text,
    age smallint check (age between 0 and 120),
    academic_background text,
    enrollment_status text,
    school_grade text,
    email text unique,
    phone_number text,
    risk_flag text,
    created_at timestamptz,
    updated_at timestamptz
);

create table if not exists raw.applications (
    id uuid primary key,
    applicant_id uuid not null references raw.applicants(id) on delete cascade,
    recruitment_type text,
    hiring_tool_url text,
    source_service text,
    applied_job text,
    desired_job text,
    current_annual_income text,
    current_title text,
    overtime_consent text,
    application_date date,
    created_at timestamptz,
    updated_at timestamptz
);
create index if not exists idx_raw_applications_applicant on raw.applications(applicant_id);
create index if not exists idx_raw_applications_date on raw.applications(application_date);

create table if not exists raw.application_events (
    application_id uuid not null references raw.applications(id) on delete cascade,
    event_type text not null,
    event_date date not null,
    minutes text,
    primary key (application_id, event_type)
);

create table if not exists raw.application_notes (
    id uuid primary key,
    application_id uuid not null references raw.applications(id) on delete cascade,
    body text not null,
    created_at timestamptz default now()
);
