
{{ config(materialized='view') }}

select *
from {{ ref('stg_revenue_adjustments_seed') }}
