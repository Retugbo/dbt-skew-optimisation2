# Handling Data Skew in dbt Models
## A Synthetic, Reproducible Case Study
## Overview

This repository demonstrates how severe **data skew** in analytical dbt models can lead to performance degradation and unstable executions, and how isolating skewed keys into separate execution paths can significantly improve reliability.

This case study is based on a **real production issue**, recreated using **fully synthetic data** so the optimisation pattern can be shared publicly without exposing proprietary or sensitive information.
## Background and Problem Statement

In analytical workloads, it is common for a small subset of keys to dominate a dataset.

In this case:

- A revenue aggregation model grouped movement-level data by **location** and **date**
- A small number of locations accounted for a **disproportionately large share of records**
- This caused **data skew** during aggregation

Observed issues included:

- Long execution times
- Unstable dbt runs
- Pressure to scale compute instead of addressing the root cause

The original model was logically correct but did not account for skewed keys.
## Baseline Approach (Pre-Optimisation)

The baseline implementation aggregates all locations together in a single execution path.

### Baseline model (`revenue_base.sql`)

```sql
select
    location_id,
    activity_date,
    count(*) as movement_count,
    sum(revenue_amount) as total_revenue
from stg_synthetic_movement
group by
    location_id,
    activity_date
```

## Why this approach breaks down

- **High-frequency keys dominate execution**  
- **Workload distribution becomes unbalanced**  
- **Aggregation stages become bottlenecks**

---

##  OPTIMISATION STRATEGY


## Optimisation Strategy

Rather than scaling infrastructure, the optimisation focuses on changing the execution pattern.

### Core principles

- Identify high-frequency (skewed) keys
- Isolate skewed keys into a dedicated execution path
- Process non-skewed data separately
- Recombine results using `UNION ALL`

This preserves business logic while improving execution behaviour.
##  Implementation Details
### Synthetic Staging Layer

Seed data is staged using standard dbt practices.

**Staging model**
- `models/staging/stg_synthetic_movement.sql`

This mimics movement-level operational data (synthetic).
### Skewed Execution Path

**Model**
- `models/marts/revenue/revenue_skewed.sql`

This model processes only the high-frequency location:

```sql
where location_id = 'SK1'
```

### Non-Skewed Execution Path

**Model**
- `models/marts/revenue/revenue_non_skewed.sql`

This model processes all other locations efficiently:

```sql
where location_id != 'SK1'
```

### Final Optimised Model

**Model**
- `models/marts/revenue/revenue_optimized.sql`

Recombines both execution paths:

```sql
select * from revenue_skewed
union all
select * from revenue_non_skewed
```
---

##  RESULTS & IMPACT


## Results and Impact

Using representative synthetic data:

- Aggregations execute more predictably
- Execution paths remain balanced
- dbt runs are more stable

This mirrors a real production fix where instability was resolved without additional compute scaling.
##  Data Privacy and Anonymisation

- All datasets are fully synthetic
- No real customer, financial, or operational data is included
- Column names, values, and distributions are anonymised
- The optimisation logic remains representative of real-world systems

This makes the repository safe for public sharing.

## Project Structure

```text
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
```
---

##  KEY TAKEAWAYS


## Key Takeaways

- Data skew is an execution problem, not just a scaling issue
- Isolating skewed keys is a simple and effective optimisation pattern
- dbt models benefit from execution-aware design
- Synthetic data can safely demonstrate real production behaviour
## Why This Project Matters

This project demonstrates:

- **Independent problem solving**
- **Production-grade optimisation thinking**
- **Ethical handling of sensitive data**
- **Clear communication of technical impact**
