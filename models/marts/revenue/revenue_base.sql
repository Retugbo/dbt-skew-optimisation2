
{{ config(materialized='table') }}

-- Baseline revenue aggregation
-- This model intentionally does NOT handle data skew
-- It represents the original performance problem

select
    location_id,
    activity_date,
    count(*) as movement_count,
    sum(revenue_amount) as total_revenue
from {{ ref('stg_synthetic_movement') }}
group by
    location_id,
    activity_date
