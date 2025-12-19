{{ config(materialized='view') }}

select *
from {{ ref('stg_events_seed') }}

