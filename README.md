# Olist E-Commerce Analytics Platform

An end-to-end analytics engineering project built on the [Olist Brazilian E-Commerce](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) public dataset. The project takes raw, denormalized e-commerce data from Kaggle all the way to a dimensional star schema on Snowflake, ready for analytics.

This is a project demonstrating two complementary analytics engineering skill sets:

* **Basic Data ingestion** — reliably moving source data into a cloud warehouse
* **Dimensional modeling** — transforming raw data into a well-reasoned star schema using dbt

## Project Purpose

This project demonstrates:

* Building a repeatable, idempotent ingestion pipeline from a public dataset into Snowflake
* Building conformed dimensions and fact tables at well-reasoned grains
* Handling messy real-world grain problems (e.g. many-to-many relationships)
* Structuring a dbt project using staging → intermediate → marts layering
* Keeping ingestion and transformation responsibilities cleanly separated

## Architecture / Data Flow

```text
Kaggle Download Script
       │
       ▼
Olist CSV Files
       │
       ▼
Python Ingestion Layer  ──────────►  see ingestion/README.MD
       │
       ▼
Snowflake RAW Schema
       │
       ▼
dbt Transformation Layer  ────────►  see olist/README.MD
 (staging → intermediate → marts)
       │
       ▼
Snowflake ANALYTICS.OLIST_MART
 (star schema: dimensions + facts)
```

## Repository Structure

```text
project-root/
├── ingestion/                    # Data ingestion layer (Python → Snowflake RAW)
│   ├── olist dataset/            # Downloaded Olist CSV files (not committed)
│   ├── sql/                      # Snowflake RAW schema setup
│   ├── download_olist_data_and_enrich_files.py
│   ├── load_olist_to_snowflake.py
│   ├── requirements.txt
│   └── README.MD                 # Full ingestion documentation → [ingestion/README.MD](ingestion/README.MD)
│
├── olist/                        # dbt transformation project (RAW → star schema)
│   ├── models/
│   │   ├── staging/
│   │   ├── intermediate/
│   │   └── marts/
│   ├── seeds/
│   ├── macros/
│   ├── dbt_project.yml
│   ├── packages.yml
│   ├── package-lock.yml
│   ├── Olist ERD.md              # Entity-relationship diagram → [olist/Olist ERD.md](<olist/Olist ERD.md>)
│   └── README.MD                 # Full dbt modeling documentation → [olist/README.MD](olist/README.MD)
│
└── README.MD                     # This file
```

## Tech Stack

| Layer | Technology |
|---|---|
| Source data | Kaggle [Olist Brazilian E-Commerce](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce/data) dataset |
| Ingestion | Python, Snowflake Python Connector |
| Warehouse | Snowflake |
| Transformation | dbt (dbt-fusion) |
| dbt packages | [`dbt_utils`](https://github.com/dbt-labs/dbt-utils) (>=1.3.0), [`codegen`](https://github.com/dbt-labs/dbt-codegen) (>=0.12.0) |

## Data Ingestion

The ingestion layer downloads the Olist CSV files from Kaggle, performs light enrichment (e.g. generating seller names), and loads the files into Snowflake's `RAW` schema via `COPY INTO`. It is intentionally kept separate from the dbt transformation layer and is designed to be safely rerunnable.

**Full documentation:** [ingestion/README.MD](ingestion/README.MD)

## Data Modeling

The dbt project transforms the raw Snowflake tables into a star schema across staging, intermediate, and marts layers, materialized as views (staging/intermediate) and tables (marts) in `ANALYTICS.OLIST_MART`. The model handles real-world grain complications, such as a many-to-many relationship between reviews and orders, using deliberate, documented design decisions rather than lossy shortcuts.

Key dimensions and facts include 
* `dim_customer`
* `dim_order_customer`
* `dim_product` 
* `dim_seller` 
* `dim_date`
* `fact_order_items`
* `fact_orders_lifecycle`
* `fact_order_payments` 
* `fact_order_reviews`

**Full documentation:** [olist/README.MD](olist/README.MD)
**ER Diagram:** [olist/Olist ERD.md](<olist/Olist ERD.md>)

## Configuration

* **Raw schema:** `RAW.OLIST` (seeds and ingested source tables)
* **Staging/intermediate schema:** `STAGING`
* **Marts schema:** `ANALYTICS.OLIST_MART`
* **Timezone:** `America/Chicago` (via `dbt_date:time_zone` var)

## Getting Started

### 1. Run the ingestion layer

```bash
cd ingestion
pip install -r requirements.txt
# configure Snowflake connection (see ingestion/README.MD)
python download_olist_data_and_enrich_files.py
python load_olist_to_snowflake.py
```

See [ingestion/README.MD](ingestion/README.MD) for prerequisites, Snowflake configuration, and detailed step-by-step instructions.

### 2. Run the dbt project

```bash
cd olist
dbt deps
dbt seed
dbt run
dbt test
dbt docs generate
dbt docs serve
```

See [olist/README.MD](olist/README.MD) for the full data model, design decisions, and testing details.

## Testing & Validation

* **Ingestion:** validates that expected source files are present and readable, that the Snowflake connection and target tables exist, and captures the result of each `COPY INTO` operation. See [ingestion/README.MD](ingestion/README.MD#data-validation).
* **dbt:** referential integrity between fact and dimension tables (e.g. `product_id` and `seller_id` on `fact_order_items`) is enforced with `relationships` tests. See [olist/README.MD](olist/README.MD#testing).

## Related Documentation

* [Data Ingestion README](ingestion/README.MD) — Kaggle download, enrichment, and Snowflake `RAW` loading
* [dbt Project README](olist/README.MD) — staging/intermediate/marts layering and star schema design
* [ER Diagram](<olist/Olist ERD.md>) — entity-relationship diagram of the star schema

## Future Learning Goals
This project focuses on dimensional modeling and doesn't cover the following, noted here as gaps I'm aware of and plan to address in future projects:
* **Orchestration:** Running the dbt project on a schedule
* **Incremental Refreshes:** Working with a changing data source
* **Snapshots:** Using dbt snapshots for Type 2 slowly changing dimensions