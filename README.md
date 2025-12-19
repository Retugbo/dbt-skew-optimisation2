# dbt Skew Handling Demo

## Overview
This repository demonstrates how to handle severe join key skew in a dbt model.  
All data is synthetic and anonymised.

## Problem
A small number of keys dominated the dataset in joins, causing:
- slow queries
- shuffle bottlenecks
- job failures

## Naive Approach
- Single join of all data
- Works for small datasets
- Fails at scale

## Optimised Approach
- Identify skewed keys
- Split skewed/non-skewed events
- Process independently
- Recombine with UNION ALL

## Synthetic Data
- `stg_events_seed.csv`
- `stg_revenue_adjustments_seed.csv`

## Models
- `fact_events_naive.sql`
- `fact_events_optimised.sql`

## How to Run
```bash
dbt seed
dbt run --models fact_events_naive
dbt run --models fact_events_optimised
