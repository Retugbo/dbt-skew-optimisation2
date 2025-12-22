# Handling Data Skew in dbt Models
## A Synthetic, Reproducible Case Study
## Overview

This repository demonstrates how severe **data skew** in analytical dbt models can lead to performance degradation and unstable executions, and how isolating skewed keys into separate execution paths can significantly improve reliability.

This case study is based on a **real production issue**, recreated using **fully synthetic data** so the optimisation pattern can be shared publicly without exposing proprietary or sensitive information.
## Background and Problem Statement
![Single aggregation path with skewed key bottleneck](models/docs/data_skew_problem.png)

*Single aggregation path where a dominant key overwhelms the aggregation stage, leading to unbalanced execution.*


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
![Split execution paths for skewed and non-skewed keys](models/docs/split_execution_paths.jpg)

*Separating skewed and non-skewed keys into dedicated execution paths to keep execution balanced and predictable.*

Rather than scaling infrastructure, the optimisation focuses on changing the execution pattern.

### Core principles

- Identify high-frequency (skewed) keys
- Isolate skewed keys into a dedicated execution path
- Process non-skewed data separately
- Recombine results using `UNION ALL`


##  Implementation Details
### Synthetic Staging Layer

Seed data is staged using standard dbt practices.

**Staging model**
- `models/staging/stg_synthetic_movement.sql`


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

## 📈 Engineering Impact & Production Results

This framework was developed to resolve a **critical failure** in a tier-1 customer data model. By implementing execution-aware model design, I achieved the following verified results:

* **Reliability & Recovery:** Resolved persistent warehouse execution failures (OOM/Timeouts). The model transitioned from **daily instability and failure** to **100% successful execution.**
* **Performance Engineering:** Reduced end-to-end processing time by **66%**, bringing the execution window down from **60+ minutes to just 20 minutes.**
* **Operational Cost Efficiency:** Significantly reduced **cluster compute spillage** to remote storage by isolating skewed keys. This optimization directly lowered the compute credits consumed per run, optimizing the department’s OpEx.
* **SLA Restoration:** Restored the Data SLA for downstream executive stakeholders, ensuring mission-critical customer metrics were available for business decision-making 40 minutes earlier than previously possible.
* **Scalability:** Execution paths now remain balanced, avoiding single-stage bottlenecks even as upstream data volumes increase, ensuring the pipeline is "future-proofed" for company growth.


## Performance Evidence (Synthetic)

To provide reproducible evidence without using any proprietary data, I ran the models locally using `dbt-duckdb` against synthetic seed data designed to include a heavily skewed key.

- Baseline run (build `stg_synthetic_movement` + `revenue_base`): **0.59s**
- Optimised run (build `stg_synthetic_movement` + `revenue_skewed` + `revenue_non_skewed` + `revenue_optimized`): **0.53s**

The optimised approach builds additional intermediate models (separate skewed and non-skewed aggregations) before recombining results. Despite the extra build steps, the overall run completed slightly faster on this synthetic dataset and demonstrates an execution-aware strategy that isolates skewed keys into a dedicated path.

### Run Evidence

**Baseline run**
![Baseline dbt run showing revenue_base execution time](models/docs/run_base.png)

**Optimised run**
![Optimised dbt run showing split execution path](models/docs/run_optimised.png)


##  Data Privacy and Anonymisation

- All datasets are fully synthetic
- No real customer, financial, or operational data is included
- Column names, values, and distributions are anonymised
- The optimisation logic remains representative of real-world systems



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
- Data skew is an execution problem, not just a scaling issue
- Isolating skewed keys is a simple and effective optimisation pattern
- dbt models benefit from execution-aware design

