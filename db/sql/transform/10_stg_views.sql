-- Pivot event timeline into a wide table per application.
create or replace view stg.application_events_pivot as
select
    application_id,
    max(case when event_type = 'カジュアル面談実施日' then event_date end) as contact_date,
    max(case when event_type = '一次面談実施日' then event_date end) as first_interview_date,
    max(case when event_type = '最終面接実施日' then event_date end) as final_interview_date,
    max(case when event_type = '内定日' then event_date end) as offer_date,
    max(case when event_type = '内定承諾日' then event_date end) as offer_accept_date,
    max(case when event_type = '入社日' then event_date end) as start_date
from raw.application_events
group by application_id;

-- Enriched application dataset with applicant attributes and stage flags.
create or replace view stg.application_journey as
select
    app.id as application_id,
    app.applicant_id,
    app.recruitment_type,
    app.application_date,
    app.source_service,
    app.applied_job,
    app.desired_job,
    app.current_title,
    app.current_annual_income,
    app.overtime_consent,
    app.created_at as application_created_at,
    app.updated_at as application_updated_at,
    applicants.applicant_name,
    applicants.sex,
    applicants.age,
    applicants.academic_background,
    applicants.enrollment_status,
    applicants.school_grade,
    applicants.email,
    applicants.risk_flag,
    events.contact_date,
    events.first_interview_date,
    events.final_interview_date,
    events.offer_date,
    events.offer_accept_date,
    events.start_date,
    (events.contact_date is not null) as stage_contact_completed,
    (events.first_interview_date is not null) as stage_first_interview_completed,
    (events.final_interview_date is not null) as stage_final_interview_completed,
    (events.offer_date is not null) as stage_offer_completed,
    (events.offer_accept_date is not null) as stage_offer_accept_completed,
    (events.start_date is not null) as stage_start_completed,
    (case
        when events.contact_date is not null and app.application_date is not null
            then (events.contact_date - app.application_date)
     end)::numeric as lead_apply_to_contact_days,
    (case
        when events.first_interview_date is not null and events.contact_date is not null
            then (events.first_interview_date - events.contact_date)
     end)::numeric as lead_contact_to_first_interview_days,
    (case
        when events.final_interview_date is not null and events.first_interview_date is not null
            then (events.final_interview_date - events.first_interview_date)
     end)::numeric as lead_first_to_final_interview_days,
    (case
        when events.offer_date is not null and events.final_interview_date is not null
            then (events.offer_date - events.final_interview_date)
     end)::numeric as lead_final_to_offer_days,
    (case
        when events.offer_accept_date is not null and events.offer_date is not null
            then (events.offer_accept_date - events.offer_date)
     end)::numeric as lead_offer_to_accept_days,
    (case
        when events.start_date is not null and events.offer_accept_date is not null
            then (events.start_date - events.offer_accept_date)
     end)::numeric as lead_accept_to_start_days
from raw.applications as app
left join raw.applicants as applicants
    on app.applicant_id = applicants.id
left join stg.application_events_pivot as events
    on events.application_id = app.id;
