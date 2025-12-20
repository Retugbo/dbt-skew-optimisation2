{{ config(materialized='table') }}

-- Handles only skewed keys
-- This isolates high-frequency locations to avoid join and aggregation bottlenecks

select
    location_id,
    activity_date,
    count(*) as movement_count,
    sum(revenue_amount) as total_revenue
from {{ ref('stg_synthetic_movement') }}
where location_id = 'SK1'
group by
    location_id,
    activity_date
