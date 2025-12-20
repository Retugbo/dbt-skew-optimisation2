Handling Data Skew in dbt Models (Synthetic Case Study)
Overview

This repository demonstrates how severe join and aggregation key skew in a dbt model can cause performance degradation and instability — and how isolating skewed keys into separate execution paths can significantly improve reliability and efficiency.

The work shown here is based on a real production issue I solved, recreated using fully synthetic data to safely demonstrate the optimisation pattern without exposing any proprietary or sensitive information.

Problem Statement

A revenue aggregation model grouped high-volume movement data by location and date.

In practice:

A small number of locations accounted for a disproportionately large share of records

Aggregations involving these locations caused data skew

This resulted in:

Long execution times

Unstable dbt runs

Pressure to scale compute rather than address the root cause

The original model aggregated all locations together, which worked logically but performed poorly at scale.

Baseline Approach (Problematic)

The baseline model (revenue_base.sql) performs a single aggregation across all locations:

select
    location_id,
    activity_date,
    count(*) as movement_count,
    sum(revenue_amount) as total_revenue
from stg_synthetic_movement
group by location_id, activity_date


While correct, this approach does not account for skewed keys, leading to uneven workload distribution during execution.

Optimisation Strategy

Rather than scaling infrastructure, the optimisation focuses on changing the execution pattern.

Key ideas:

Identify skewed keys (high-frequency locations)

Isolate skewed data into a dedicated execution path

Process non-skewed data separately

Recombine results using UNION ALL

This ensures:

Skewed keys do not dominate a single aggregation stage

Distributed processing remains balanced

Business logic remains unchanged

Implementation
1. Staging Layer

Synthetic seed data is staged via stg_synthetic_movement.sql, following standard dbt best practices.

2. Skewed Path

revenue_skewed.sql processes only high-frequency locations:

where location_id = 'SK1'

3. Non-Skewed Path

revenue_non_skewed.sql handles the remaining majority of locations efficiently:

where location_id != 'SK1'

4. Final Optimised Model

The final model (revenue_optimized.sql) recombines both paths:

select * from revenue_skewed
union all
select * from revenue_non_skewed

Results

Using representative synthetic data:

Execution paths are more balanced

Aggregations complete more predictably

The optimisation pattern mirrors the fix applied in production, where it stabilised dbt runs and removed the need for additional compute scaling

Data & Privacy

All datasets are fully synthetic

No real customer, financial, or operational data is included

Column names, values, and distributions are anonymised

The optimisation pattern and engineering decisions remain representative of real-world usage

This approach ensures the project is safe to share publicly while preserving technical authenticity.

Project Structure
models/
  staging/
    stg_synthetic_movement.sql
  marts/
    revenue/
      revenue_base.sql
      revenue_skewed.sql
      revenue_non_skewed.sql
      revenue_optimized.sql
seeds/
  movement_non_skewed.csv
  movement_skewed.csv

Key Takeaway

Performance issues caused by data skew are often best solved by changing execution strategy, not by scaling infrastructure.

Isolating skewed keys into dedicated execution paths is a simple but powerful pattern that can dramatically improve dbt model reliability in distributed environments.
