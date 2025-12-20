{{ config(materialized='table') }}

-- Final optimised revenue model
-- Combines skewed and non-skewed execution paths

select * from {{ ref('revenue_skewed') }}

union all

select * from {{ ref('revenue_non_skewed') }}

