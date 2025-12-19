
{{ config(materialized='table') }}

with revenue_adjustments as (
    select
        entity_key,
        period_key,
        adjustment_category,
        sum(adjustment_amount) as adjustment_amount
    from {{ ref('stg_revenue_adjustments') }}
    group by entity_key, period_key, adjustment_category
)

select
    e.event_id,
    e.event_business_key,
    e.entity_key,
    sum(coalesce(r.adjustment_amount,0)) as non_core_amount
from {{ ref('stg_events') }} e
left join revenue_adjustments r
    on r.entity_key = e.entity_key
    and r.period_key = e.period_key
group by e.event_id, e.event_business_key, e.entity_key
