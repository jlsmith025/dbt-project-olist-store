# Olist E-Commerce Analytics — dbt Project

A dimensional data warehouse built on the [Olist Brazilian E-Commerce](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) public dataset, implemented as a dbt project on Snowflake. This project models raw, denormalized e-commerce data into a star schema optimized for analytics.

## Project Purpose

This is a portfolio project demonstrating dimensional modeling and analytics engineering practices: 
* building conformed dimensions and fact tables at well-reasoned grains
* handling messy real-world grain problems (e.g. many-to-many relationships)
* structuring a dbt project using staging → intermediate → marts layering.

## Tech Stack

* **Transformation:** dbt (dbt-fusion)
* **Warehouse:** Snowflake
* **Source data:** Kaggle [Olist Brazilian E-Commerce](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce/data) dataset, loaded as raw tables plus a `brazil_holidays` seed
* **Packages:**
  * [`dbt_utils`](https://github.com/dbt-labs/dbt-utils) (>=1.3.0)
  * [`codegen`](https://github.com/dbt-labs/dbt-codegen) (>=0.12.0)

## Project Structure

```
olist/
├── models/
│   ├── staging/        # 1:1 views over raw sources, light cleaning/renaming
│   ├── intermediate/   # Reusable transformation logic between staging and marts
│   └── marts/          # Final star schema (dimensions + facts), materialized as tables
|
├── seeds/
│   └── brazil_holidays  # Holiday calendar seed, loaded to RAW.OLIST
|
├── macros/
├── snapshots/
├── tests/
└── dbt_project.yml
```

Models are materialized as **views** in staging and intermediate layers and as **tables** in the marts layer, balancing build speed against query performance for the final analytics-facing schema.

## Data Model

The warehouse is organized as a star schema at multiple grains, connected by shared keys (`customer_order_key`, `customer_unique_key`, `product_id`, `seller_id`, etc.).

### Dimensions

| Table | Grain | Notes |
|---|---|---|
| `dim_customer` | 1 row per customer | Holds customer-grain measures (e.g. total number of purchases, customer lifetime value) that don't fit an order-grain table |
| `dim_order_customer` | 1 row per order | Combines order + customer attributes at order grain from Olist source |
| `dim_product` | 1 row per product | |
| `dim_seller` | 1 row per seller | |
| `dim_date` | 1 row per date from 2026 - 2020 | Generated with `dbtutils.date_spine()` |

### Facts

| Table | Grain | Notes |
|---|---|---|
| `fact_order_items` | 1 row per `order_id` + `order_item_id` | Core transactional fact. Pulls in the `orders` source (beyond raw `order_items`) for `order_purchase_date_sk` and `order_status`. `product_id`/`seller_id` are kept as bare foreign keys, validated via `relationships` tests against `dim_product` and `dim_seller` |
| `fact_orders_lifecycle` | 1 row per order | Accumulating snapshot fact holding lifecycle timestamps/date surrogate keys and derived lag measures (e.g. `delivery_delay_days`) |
| `fact_order_payments` | 1 row per `order_id` + `payment_sequential` | Joinable to other facts via `order_id` |
| `fact_order_reviews` | Composite grain: `review_id` + `order_id` | `review_id` and `order_id` have a many-to-many relationship in the source data with no clean single grain. Rather than deduping to a single key, this grain is preserved with an allocation weight column to correctly distribute review-level measures across associated orders |

### Design Decisions Worth Noting

* **Flattened customer grain dimension.** The `customers` source data has a grain of customer + order with the possibility of different location per order. A flattened customer dimension allows analysis using the latest available location.
* **Order facts** can join to the `dim_customer` for customer grain dimensions or `dim_order_customer` for order customer grain dimensions
* **No separate order-grain fact table.** Order-level measures are computed via aggregation on `fact_order_items` instead of maintaining a duplicate fact, avoiding redundant storage and potential drift.
* **Accumulating snapshot for order lifecycle.** `fact_orders_lifecycle` isolates lifecycle timestamps and lag calculations (like delivery delay) so that grain and update patterns specific to lifecycle tracking don't bleed into `dim_order_customer`.
* **Many-to-many resolved with an allocation weight**, not a dedup. `fact_order_reviews` preserves the true relationship in the source data rather than arbitrarily picking one review per order or vice versa, which would silently drop information.

### ER Diagram
[Olist ERD.md](<Olist ERD.md>)

## Configuration

* **Target database/schema layout:**
  * Staging and intermediate models → `STAGING` schema
  * Marts models → `ANALYTICS.OLIST_MART` schema
  * Seeds → `RAW.OLIST` schema
* **Timezone:** `America/Chicago` (via `dbt_date:time_zone` var)

## Getting Started

```bash
# Install dependencies
dbt deps

# Load seeds (e.g. holiday calendar)
dbt seed

# Build all models
dbt run

# Run tests
dbt test

# Generate and view docs
dbt docs generate
dbt docs serve
```

## Testing

Referential integrity between fact and dimension tables (e.g. `product_id` and `seller_id` on `fact_order_items`) is enforced with `relationships` tests.
