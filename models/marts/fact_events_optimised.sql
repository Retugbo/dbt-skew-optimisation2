
{{ config(materialized='table') }}

with revenue_adjustments as (
    select
        entity_key,
        period_key,
        adjustment_category,
        sum(adjustment_amount) as adjustment_amount
    from {{ ref('stg_revenue_adjustments') }}
    group by entity_key, period_key, adjustment_category
),

skewed_keys as (
    select entity_key
    from {{ ref('stg_events') }}
    group by entity_key
    having count(*) > {{ var('skew_threshold', 2) }}  -- very low for synthetic demo
),

non_skewed_events as (
    select *
    from {{ ref('stg_events') }}
    where entity_key not in (select entity_key from skewed_keys)
),

skewed_events as (
    select *
    from {{ ref('stg_events') }}
    where entity_key in (select entity_key from skewed_keys)
),

main_non_skewed as (
    select
        e.event_id,
        e.event_business_key,
        e.entity_key,
        sum(coalesce(r.adjustment_amount, 0)) as non_core_amount
    from non_skewed_events e
    left join revenue_adjustments r
        on r.entity_key = e.entity_key
        and r.period_key = e.period_key
    group by e.event_id, e.event_business_key, e.entity_key
),

main_skewed as (
    select
        e.event_id,
        e.event_business_key,
        e.entity_key,
        sum(coalesce(r.adjustment_amount, 0)) as non_core_amount
    from skewed_events e
    left join revenue_adjustments r
        on r.entity_key = e.entity_key
        and r.period_key = e.period_key
    group by e.event_id, e.event_business_key, e.entity_key
)

select * from main_non_skewed
union all
select * from main_skewed
