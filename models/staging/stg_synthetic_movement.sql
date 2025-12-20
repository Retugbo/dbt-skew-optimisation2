{{ config(materialized='view') }}

-- Staging model built on synthetic data
-- Mimics movement-level operational records
-- Used to demonstrate data skew and optimisation patterns

select
    location_id,
    activity_date,
    revenue_amount
from {{ ref('movement_non_skewed') }}

union all

select
    location_id,
    activity_date,
    revenue_amount
from {{ ref('movement_skewed') }}

