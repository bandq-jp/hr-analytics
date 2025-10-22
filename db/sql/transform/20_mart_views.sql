-- Conversion rates per stage and recruitment type.
create or replace view mart.stage_conversion as
with base as (
    select
        recruitment_type,
        stage_contact_completed,
        stage_first_interview_completed,
        stage_final_interview_completed,
        stage_offer_completed,
        stage_offer_accept_completed,
        stage_start_completed
    from stg.application_journey
),
stage_data as (
    select
        recruitment_type,
        '応募->連絡'::text as stage_label,
        count(*) as base_count,
        count(*) filter (where stage_contact_completed) as progressed_count
    from base
    group by recruitment_type
    union all
    select
        recruitment_type,
        '連絡->一次面接'::text as stage_label,
        count(*) filter (where stage_contact_completed) as base_count,
        count(*) filter (where stage_first_interview_completed) as progressed_count
    from base
    group by recruitment_type
    union all
    select
        recruitment_type,
        '一次面接->最終面接'::text as stage_label,
        count(*) filter (where stage_first_interview_completed) as base_count,
        count(*) filter (where stage_final_interview_completed) as progressed_count
    from base
    group by recruitment_type
    union all
    select
        recruitment_type,
        '最終面接->内定'::text as stage_label,
        count(*) filter (where stage_final_interview_completed) as base_count,
        count(*) filter (where stage_offer_completed) as progressed_count
    from base
    group by recruitment_type
    union all
    select
        recruitment_type,
        '内定->内定承諾'::text as stage_label,
        count(*) filter (where stage_offer_completed) as base_count,
        count(*) filter (where stage_offer_accept_completed) as progressed_count
    from base
    group by recruitment_type
    union all
    select
        recruitment_type,
        '内定承諾->入社'::text as stage_label,
        count(*) filter (where stage_offer_accept_completed) as base_count,
        count(*) filter (where stage_start_completed) as progressed_count
    from base
    group by recruitment_type
)
select
    recruitment_type,
    stage_label,
    base_count,
    progressed_count,
    case
        when base_count = 0 then null
        else round(progressed_count::numeric / base_count, 4)
    end as pass_rate
from stage_data
order by recruitment_type, stage_label;

-- Average lead time in days per stage.
create or replace view mart.lead_time_days as
with base as (
    select
        recruitment_type,
        lead_apply_to_contact_days,
        lead_contact_to_first_interview_days,
        lead_first_to_final_interview_days,
        lead_final_to_offer_days,
        lead_offer_to_accept_days,
        lead_accept_to_start_days
    from stg.application_journey
),
aggregate as (
    select
        recruitment_type,
        '応募->連絡'::text as stage_label,
        round(avg(lead_apply_to_contact_days), 2) as avg_days
    from base
    where lead_apply_to_contact_days is not null
    group by recruitment_type
    union all
    select
        recruitment_type,
        '連絡->一次面接'::text as stage_label,
        round(avg(lead_contact_to_first_interview_days), 2) as avg_days
    from base
    where lead_contact_to_first_interview_days is not null
    group by recruitment_type
    union all
    select
        recruitment_type,
        '一次面接->最終面接'::text as stage_label,
        round(avg(lead_first_to_final_interview_days), 2) as avg_days
    from base
    where lead_first_to_final_interview_days is not null
    group by recruitment_type
    union all
    select
        recruitment_type,
        '最終面接->内定'::text as stage_label,
        round(avg(lead_final_to_offer_days), 2) as avg_days
    from base
    where lead_final_to_offer_days is not null
    group by recruitment_type
    union all
    select
        recruitment_type,
        '内定->内定承諾'::text as stage_label,
        round(avg(lead_offer_to_accept_days), 2) as avg_days
    from base
    where lead_offer_to_accept_days is not null
    group by recruitment_type
    union all
    select
        recruitment_type,
        '内定承諾->入社'::text as stage_label,
        round(avg(lead_accept_to_start_days), 2) as avg_days
    from base
    where lead_accept_to_start_days is not null
    group by recruitment_type
)
select
    recruitment_type,
    stage_label,
    avg_days
from aggregate
order by recruitment_type, stage_label;

-- Offer and hire conversion metrics.
create or replace view mart.offer_rate as
with summary as (
    select
        recruitment_type,
        count(*) as applications,
        count(*) filter (where stage_offer_completed) as offers,
        count(*) filter (where stage_offer_accept_completed) as offer_accepts,
        count(*) filter (where stage_start_completed) as hires
    from stg.application_journey
    group by recruitment_type
)
select
    recruitment_type,
    applications,
    offers,
    offer_accepts,
    hires,
    case when applications = 0 then null else round(offers::numeric / applications, 4) end as offer_rate,
    case when offers = 0 then null else round(offer_accepts::numeric / offers, 4) end as offer_accept_rate,
    case when applications = 0 then null else round(hires::numeric / applications, 4) end as hire_rate
from summary
order by recruitment_type;
