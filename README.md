# IFF Taste Data Analytics – Data Engineering Hiring Challenge

## Overview

This project implements a **medallion-architecture data pipeline** for IFF Taste Analytics using **dbt** and **DuckDB**. It ingests raw CSV data, cleans and models it through Bronze → Silver → Gold layers, and exposes a dimensional model ready for BI dashboards.

---

## Quick Start

### Prerequisites
- Python 3.9+
- pip

### Setup

```bash
# 1. Install dependencies (pinned versions in requirements.txt)
pip install -r requirements.txt

# 2. Navigate to project root
cd iff_taste_dbt

# 3. Load seed data (raw CSVs → DuckDB)
dbt seed --profiles-dir .

# 4. Run all models (Bronze → Silver → Gold)
dbt run --profiles-dir .

# 5. Run all data quality tests
dbt test --profiles-dir .
```

### Explore the data

```bash
# Open DuckDB interactive shell
python3 -c "
import duckdb
con = duckdb.connect('iff_taste.duckdb')
con.execute('.schema').fetchall()
"
```

Or use any DuckDB-compatible client (DBeaver, TablePlus, etc.) and point it at `iff_taste.duckdb`.

---

## Architecture

### Medallion Layers

```
Raw CSVs  →  [Bronze]  →  [Silver]  →  [Gold]
               Type          Clean        Dimensional
               cast         Deduplicate    Model
```

| Layer | Schema | Materialization | Purpose |
|-------|--------|-----------------|---------|
| Raw (seeds) | `main_raw` | Table | Exact CSV data loaded into DuckDB |
| Bronze | `main_bronze` | Table | Type casting, whitespace trimming, null normalisation |
| Silver | `main_silver` | Table | Deduplication (latest batch wins), country normalisation, SCD2 for flavours |
| Gold | `main_gold` | Table | Dimensions + Fact tables for analytics |

### Why tables for Bronze?

During development, a **DuckDB 1.5 internal bug** was encountered: `ROW_NUMBER()` window functions in CTEs that reference a *view* (rather than a table) over columns containing DATE values trigger an assertion failure (`inequal types: DATE != VARCHAR`). Making Bronze models materialised tables instead of views resolves this completely. This is documented in the model comments.

---

## Data Model (Gold Layer)

```
                    ┌───────────────┐
                    │  dim_country  │
                    │  (BONUS)      │
                    └───────┬───────┘
                            │ FK
          ┌─────────────────┼──────────────────┐
          │                 │                  │
   ┌──────┴──────┐  ┌───────┴───────┐  ┌──────┴──────┐
   │ dim_provider│  │ dim_customer  │  │   dim_date  │
   └──────┬──────┘  └───────┬───────┘  └──────┬──────┘
          │                 │                  │
          │    ┌────────────┴──────────────────┘
          │    │            │
   ┌──────┴────┴──┐  ┌──────┴──────────────────┐
   │fact_provider │  │ fact_sales_transactions  │
   │_inventory    │  │                          │
   └──────────────┘  └──────┬──────────────────┘
                             │ FK
                      ┌──────┴──────┐
                      │ dim_flavour │◄── dim_flavour_history
                      └──────┬──────┘     (SCD2)
                             │
                      ┌──────┴──────────┐
                      │  fact_recipes   │
                      └────┬─────┬──────┘
                           │     │
              ┌────────────┘     └─────────────┐
       ┌──────┴──────┐            ┌────────────┴──────┐
       │dim_raw_     │            │  dim_ingredient   │
       │material     │            │  (embeds provider)│
       └─────────────┘            └───────────────────┘
```

### Dimensions

| Dimension | Grain | Key Design Decision |
|-----------|-------|---------------------|
| `dim_country` | 1 row per unique country name | Unified from 3 sources; handles case inconsistency |
| `dim_provider` | 1 row per provider | FK to dim_country |
| `dim_customer` | 1 row per customer | FK to dim_country |
| `dim_flavour` | 1 row per flavour (current) | Simple snapshot for FK integrity |
| `dim_flavour_history` | 1 row per flavour version | SCD Type 2; powers Description Tracker |
| `dim_ingredient` | 1 row per ingredient | Denormalises provider info for convenience |
| `dim_raw_material` | 1 row per raw material | Simple lookup |
| `dim_date` | 1 row per calendar day | Spans transaction date range; includes year/quarter labels |

### Facts

| Fact | Grain | Key Measures |
|------|-------|--------------|
| `fact_provider_inventory` | 1 row per ingredient | `weight_in_grams`, `cost_per_gram`, `stock_value_dollar` |
| `fact_sales_transactions` | 1 row per transaction | `amount_dollar`, `quantity_liters` |
| `fact_recipes` | 1 row per recipe | `raw/flavour/ingredient_ratio`, `yield_pct` |

---

## Flavour SCD Type 2 Design

The flavours dataset arrived in **two batches**. Batch 2 contains updated descriptions for some flavours.

- **`slv_flavours_history`** (Silver): Preserves all versions. A new version row is only created when the description *changes* between batches. Uses MD5(flavour_id + batch_number) as surrogate key.
- **`slv_flavours_current`** (Silver): Simple deduplication — highest batch_number wins per flavour_id. Used for FK integrity in fact tables.
- **`dim_flavour_history`** (Gold): Exposes the history table directly. Powers the **Flavour Description Tracker** dashboard.

---

## Country Dimension (Bonus)

**Challenge**: Country names arrive in three different formats across sources:
- `providers.csv`: Title Case — `"United Kingdom"`, `"South Africa"`
- `customers.csv`: Title Case — `"USA"`, `"UK"`  *(abbreviated forms)*
- `sales_transactions.csv`: ALL CAPS — `"INDIA"`, `"GERMANY"`

**Approach**:
1. In Silver, all country strings are normalised to Title Case using a DuckDB `list_transform` macro (`title_case`).
2. `dim_country` takes the `UNION DISTINCT` of all normalised country values and assigns a `country_key`.
3. The `appears_in_sources` column tracks which datasets each country appears in, enabling data lineage tracing.

**Known limitation**: Abbreviated forms (`USA` → `Usa`, `UK` → `Uk`) don't match their full equivalents (`United States`, `United Kingdom`). A proper fix would require a reference table (ISO 3166) to standardise abbreviations. This is documented as a known gap.

---

## Data Quality

### Tests (63 total, defined in `models/schema.yml` and `tests/`)

| Test Type | Count | Description |
|-----------|-------|-------------|
| Uniqueness | 16 | Primary keys on all dimensions and facts |
| Not-null | 18 | Required fields across all layers |
| Referential integrity | 8 | FK relationships in fact tables |
| Custom singular tests | 4 | Business rule validations |

### Custom Tests

| Test | What it checks | Failure action |
|------|----------------|----------------|
| `assert_ingredient_costs_positive` | `cost_per_gram > 0`, `weight_in_grams > 0` | Quarantine row, alert data steward |
| `assert_recipe_ratios_sum_valid` | `raw_material + flavour + ingredient ratio ≈ 1.0` | Log to DQ table, alert operations team |
| `assert_recipe_yield_valid` | `0 < yield_pct <= 100` | Reject recipe, alert operations team |
| `assert_sales_amounts_positive` | `amount_dollar > 0` | Exclude from revenue KPIs, alert sales ops |

### Known Data Quality Issues Found

| Issue | Count | Impact | Recommended Action |
|-------|-------|--------|--------------------|
| **Zero-quantity sales** | 475 transactions | Revenue reporting (quantity = 0 but charged) | Investigate with sales ops; may be service charges |
| **Zero-amount sales** | 22 transactions | Revenue under-counting | Escalate to sales ops; likely data entry errors |
| **Missing ingredient master data** | IDs 1–100 missing from `ingredients.csv` | 55,841 recipe rows have no provider/cost info | Request missing ingredient data from upstream |

### How We Handle Test Failures

1. **Blocking failures** (data cannot be trusted): Pipeline stops; alert data steward. Example: duplicate primary keys, negative costs.
2. **Warning-level findings** (data can be used with caveats): Logged to a monitoring table; analysts are notified via dashboard tooltips. Example: zero-quantity sales.
3. **Data completeness gaps**: Document in lineage; downstream reports exclude affected rows until data is remediated.

---

## LLM Tool Usage

I took help from copilot for the documentation and some portion of the code:

- **What I used it for**: Generating boilerplate SQL patterns (CTE deduplication templates, date spine queries), drafting README structure, suggesting test naming conventions.
- **What I did myself**: All architectural decisions (layer design, SCD2 strategy, country dimension approach), debugging the DuckDB 1.5 lambda/DATE bug (required iterative testing to find the root cause), interpreting data quality findings, and all business logic decisions.
- **Transparency**: Every model was verified by running the compiled SQL directly in DuckDB Python before trusting dbt output. The DuckDB bug was found through systematic debugging, not LLM suggestion.

---

## Project Structure

```
iff_taste_dbt/
├── dbt_project.yml              # Project config; layer schemas and materializations
├── profiles.yml                 # DuckDB connection config
├── macros/
│   └── title_case.sql           # DuckDB word-by-word title case helper
├── seeds/                       # Raw CSV data files
│   ├── customers.csv
│   ├── flavours.csv
│   ├── ingredients.csv
│   ├── providers.csv
│   ├── raw_materials.csv
│   ├── recipes.csv
│   └── sales_transactions.csv
├── models/
│   ├── schema.yml               # Column docs, uniqueness/FK/not-null tests
│   ├── bronze/                  # brz_* : type cast + trim (materialised as tables)
│   ├── silver/                  # slv_* : deduplicated, normalised, SCD2 flavours
│   └── gold/                    # dim_* + fact_* : dimensional model
├── tests/                       # Custom singular tests
│   ├── assert_ingredient_costs_positive.sql
│   ├── assert_recipe_ratios_sum_valid.sql
│   ├── assert_recipe_yield_valid.sql
│   ├── assert_sales_amounts_positive.sql
│   ├── assert_sales_zero_quantity_warning.sql
│   └── assert_recipe_ingredient_fk_gap.sql
└── docs/
    └── dashboard_queries.sql    # Sample SQL for all 4 dashboards + bonus
```
