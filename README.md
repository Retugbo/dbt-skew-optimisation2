Handling Data Skew in dbt Models
A Synthetic, Reproducible Case Study
1. Overview

This repository demonstrates how severe data skew in analytical dbt models can lead to performance degradation and unstable executions, and how isolating skewed keys into separate execution paths can significantly improve reliability.

The implementation is based on a real production issue, recreated using fully synthetic data to safely demonstrate the optimisation pattern without exposing any proprietary or sensitive information.

2. Background and Problem Statement

In analytical workloads, it is common for a small subset of keys to dominate a dataset.

In this case:

A revenue aggregation model grouped movement-level data by location and date

A small number of locations accounted for a disproportionately large share of records

This caused data skew during aggregation

Observed issues included:

Long execution times

Unstable dbt runs

Pressure to scale compute instead of fixing the root cause

The original model was logically correct but did not account for skewed keys.

3. Baseline Approach (Pre-Optimisation)

The baseline implementation aggregates all locations together in a single execution path.

Baseline model – revenue_base.sql
select
    location_id,
    activity_date,
    count(*) as movement_count,
    sum(revenue_amount) as total_revenue
from stg_synthetic_movement
group by
    location_id,
    activity_date

Why this approach breaks down

High-frequency keys dominate execution

Workload distribution becomes unbalanced

Aggregation stages become bottlenecks

4. Optimisation Strategy

Rather than scaling infrastructure, the optimisation focuses on changing the execution pattern.

Core principles

Identify high-frequency (skewed) keys

Isolate skewed keys into a dedicated execution path

Process non-skewed data separately

Recombine results using UNION ALL

This approach preserves business logic while improving execution behaviour.

5. Implementation Details
5.1 Synthetic Staging Layer

Synthetic seed data is staged using standard dbt practices.

Staging model:

stg_synthetic_movement.sql

This mimics realistic movement-level operational data.

5.2 Skewed Execution Path

Model:

revenue_skewed.sql

Processes only high-frequency locations:

where location_id = 'SK1'


This prevents skewed keys from overwhelming aggregation stages.

5.3 Non-Skewed Execution Path

Model:

revenue_non_skewed.sql

Handles the majority of locations efficiently:

where location_id != 'SK1'

5.4 Final Optimised Model

Model:

revenue_optimized.sql

Recombines both execution paths:

select * from revenue_skewed
union all
select * from revenue_non_skewed


This produces a single optimised output with identical results.

6. Results and Impact

Using representative synthetic data:

Aggregations execute more predictably

Execution paths remain balanced

dbt runs are more stable

The optimisation mirrors a real production fix where instability was resolved without additional compute scaling.

7. Data Privacy and Anonymisation

All datasets are fully synthetic

No real customer, financial, or operational data is included

Column names, values, and distributions are anonymised

The optimisation logic remains representative of real-world systems

This makes the repository safe for public sharing.

8. Project Structure
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

9. Key Takeaways

Data skew is an execution problem, not just a scaling issue

Isolating skewed keys is a simple and effective optimisation pattern

dbt models benefit from execution-aware design

Synthetic data can safely demonstrate real production behaviour

10. Why This Project Matters

This project demonstrates:

Independent problem solving

Production-grade optimisation thinking

Ethical handling of sensitive data

Clear communication of technical impact
