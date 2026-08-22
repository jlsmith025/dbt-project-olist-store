# Data Ingestion

This ingestion layer is the first stage of the Olist analytics pipeline. It downloads the publicly available Olist dataset, performs limited source-file enrichment, and loads the resulting files into Snowflake's `RAW` schema. The downstream dbt project uses these raw tables as its source layer for staging, transformation, testing, and analytical modeling.

## Overview

This directory contains the data ingestion layer for the Olist e-commerce analytics project.  

The ingestion process is responsible for downloading the Olist CSV files from Kaggle and loading them into Snowflake as raw source tables. The ingestion process is designed to be safely rerunnable. Because the source files are static and do not change, Snowflake's `COPY INTO` command can identify files that have already been loaded and skip them on subsequent runs.

The ingestion layer is intentionally kept separate from the dbt transformation layer so that raw data can be loaded and validated independently of downstream transformations and to handle data cleaning with dbt.  

### Data Flow

```text
Kaggle Download Script
       │
       ▼
Olist CSV Files
       │
       ▼
Python Ingestion Script
       │
       ├── CSV processing
       ├── Snowflake staging
       └── COPY INTO
       │
       ▼
Snowflake RAW Schema
       │
       ▼
Downstream dbt transformation
```

## Ingestion Directory

```text
ingestion/
├── olist dataset/                                      # Olist CSV files downloaded through ingestion process (not committed to GitHub)
|
├── sql/ 
|   └── snowflake RAW database setup.sql                # SQL script to create database, schema, and tables in Snowflake
|
├── download_olist_data_and_enrich_files.py             # Python script to download and enrich Olist data from Kaggle
├── load_olist_to_snowflake.py                          # Python script to load Olist data to Snowflake in RAW schema
├── README.MD                                           # This file
└── requirements.txt                                    # Python packages required by the ingestion scripts
```
## Source Data

The project uses the publicly available [Olist Brazilian E-Commerce Public Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce).

The dataset consists of CSV files representing different aspects of the Olist marketplace, including:

| Source File                             | Description                                         |
| --------------------------------------- | --------------------------------------------------- |
| `olist_customers_dataset.csv`           | Customer information                                |
| `olist_geolocation_dataset.csv`         | Brazilian ZIP code and geographic information       |
| `olist_orders_dataset.csv`              | Order-level information and timestamps              |
| `olist_order_items_dataset.csv`         | Products associated with orders                     |
| `olist_order_payments_dataset.csv`      | Payment information                                 |
| `olist_order_reviews_dataset.csv`       | Customer reviews                                    |
| `olist_products_dataset.csv`            | Product information                                 |
| `olist_sellers_dataset.csv`             | Seller information                                  |
| `product_category_name_translation.csv` | Portuguese-to-English product category translations |

## Technology

The ingestion process uses:

* **Python:** Ingestion and file-processing logic
* **Snowflake:** Cloud data warehouse
* **Snowflake Python Connector:** Database connectivity
* **CSV:** Source data format

## Ingestion Process

The ingestion scripts perform the following general steps:

### Download and enrich Olist data
`download_olist_data_and_enrich_files.py`  
  1. Download the CSV files from Kaggle
  2. Enrich the sellers table with a seller name generated using the Faker package

### Load the Olist CSV files to Snowflake `RAW` schema
`load_olist_to_snowflake.py`  

*Requires database, schema, and tables to be created in Snowflake with `snowflake RAW database setup.sql`*  
  1. Connect to Snowflake.
  2. Create a file format and stage in Snowflake
  3. Load the Olist source files into the Snowflake stage
  4. Execute `COPY INTO` commands to load the data into `RAW` schema tables.
  5. Capture the result of each load operation.
  6. Report the number of files/rows processed and any failures.
  7. Close the Snowflake connection.

## Snowflake Architecture

Raw source data is loaded into a dedicated `RAW` Snowflake schema.

```text
SNOWFLAKE DATABASE
│
├── RAW
│   ├── CUSTOMERS
│   ├── GEOLOCATION
│   ├── ORDERS
│   ├── ORDER_ITEMS
│   ├── ORDER_PAYMENTS
│   ├── ORDER_REVIEWS
│   ├── PRODUCTS
│   ├── SELLERS
│   └── PRODUCT_CATEGORY_TRANSLATION

```

The raw layer is intended to preserve the source data without transformation. Business logic and analytical transformations are handled downstream in dbt.

## Running the Ingestion

### Prerequisites

The following are required:

* Python 3.x
* A Snowflake account
* The Snowflake Python Connector
* Access to the Olist CSV dataset

Install the Python dependencies with:

```bash
pip install -r requirements.txt
```

### Snowflake Configuration

Snowflake connection information is not stored directly in the ingestion script or committed to source control. The ingestion process uses the local Snowflake connection configuration.

Example:

```text
~/.snowflake/connections.toml
```

The connection configuration specifies the required Snowflake account, user, authentication method, and warehouse information.

> Never commit passwords, private keys, access tokens, or other credentials to Git.

### Execute the Ingestion

#### Step 1: Download and enrich the Olist data

From the project directory:

```bash
python download_olist_data_and_enrich_files.py
```

The script reports the status of each phase of the download and enrichment process, for example:

```text
======================================================================
Olist Data Downloaded to Ingestion\olist dataset
======================================================================


====================================================================================================
Added Faker generated seller company names to Ingestion\olist dataset\olist_sellers_dataset.csv
====================================================================================================
```

#### Step 2: Ingest the Olist data into Snowflake

From the project directory:

```bash
python load_olist_to_snowflake.py
```

The script will report the status of each file with timestamps and a summary table, for example:  
*see [appendix](#appendix) for other output examples*

```text
2026-08-22 11:07:40,187  INFO     Snowflake Connector for Python Version: 4.7.2, Python Version: 3.14.7, Platform: Windows-11-10.0.26200-SP0
2026-08-22 11:07:40,188  INFO     Connecting to GLOBAL Snowflake domain
2026-08-22 11:07:43,913  INFO     Processing olist_customers_dataset.csv -> CUSTOMERS
2026-08-22 11:07:47,091  INFO     Processing olist_geolocation_dataset.csv -> GEOLOCATION
2026-08-22 11:07:55,047  INFO     Processing olist_order_items_dataset.csv -> ORDER_ITEMS
2026-08-22 11:07:58,450  INFO     Processing olist_order_payments_dataset.csv -> ORDER_PAYMENTS
2026-08-22 11:08:00,345  INFO     Processing olist_order_reviews_dataset.csv -> ORDER_REVIEWS
2026-08-22 11:08:03,517  INFO     Processing olist_orders_dataset.csv -> ORDERS
2026-08-22 11:08:07,023  INFO     Processing olist_products_dataset.csv -> PRODUCTS
2026-08-22 11:08:08,290  INFO     Processing olist_sellers_dataset.csv -> SELLERS
2026-08-22 11:08:09,454  INFO     Processing product_category_name_translation.csv -> PRODUCT_CATEGORY_NAME_TRANSLATION

Load Summary:
┌───────────────────────────────────────┬───────────────────────────────────┬──────────┬───────────────┬───────────────┐
│ file                                  │ table                             │ status   │   rows_parsed │   rows_loaded │
├───────────────────────────────────────┼───────────────────────────────────┼──────────┼───────────────┼───────────────┤
│ olist_customers_dataset.csv           │ CUSTOMERS                         │ LOADED   │         99441 │         99441 │
│ olist_geolocation_dataset.csv         │ GEOLOCATION                       │ LOADED   │       1000163 │       1000163 │
│ olist_order_items_dataset.csv         │ ORDER_ITEMS                       │ LOADED   │        112650 │        112650 │
│ olist_order_payments_dataset.csv      │ ORDER_PAYMENTS                    │ LOADED   │        103886 │        103886 │
│ olist_order_reviews_dataset.csv       │ ORDER_REVIEWS                     │ LOADED   │         99224 │         99224 │
│ olist_orders_dataset.csv              │ ORDERS                            │ LOADED   │         99441 │         99441 │
│ olist_products_dataset.csv            │ PRODUCTS                          │ LOADED   │         32951 │         32951 │
│ olist_sellers_dataset.csv             │ SELLERS                           │ LOADED   │          3095 │          3095 │
│ product_category_name_translation.csv │ PRODUCT_CATEGORY_NAME_TRANSLATION │ LOADED   │            71 │            71 │
└───────────────────────────────────────┴───────────────────────────────────┴──────────┴───────────────┴───────────────┘
```

### Data Loading Strategy

The ingestion layer uses Snowflake's bulk loading capabilities rather than inserting individual records from Python.

The general pattern is:

```text
Local CSV
   │
   ▼
Snowflake Stage
   │
   ▼
COPY INTO
   │
   ▼
RAW Schema Table
```

Using `COPY INTO` allows Snowflake to perform the bulk loading operation and is more appropriate for this dataset than issuing one `INSERT` statement per record.

## Error Handling

The ingestion process reports the status of each file independently, making it possible to identify failures while still reporting successful file loads.

Typical failure categories include:

* Missing source files
* Invalid CSV formatting
* Snowflake connection failures
* Authentication failures
* Incorrect table definitions
* Data type conversion errors
* Snowflake `COPY INTO` failures

The ingestion process fails clearly and provides enough information to identify which file or operation caused the problem.

## Data Validation

Basic validation is performed during ingestion, including:

* The expected source files are present.
* The CSV files can be read.
* The Snowflake connection can be established.
* The required Snowflake database, schema, and tables exist before loading.
* Snowflake reports the result of each `COPY INTO` operation.

The ingestion process also captures the result of each `COPY INTO` operation to identify successful loads and failures.

More comprehensive data-quality testing is performed downstream using dbt.

## Idempotency

The ingestion process is safe to run repeatedly. 

### Data download and enrichment
The process for downloading an enriching Olist data pulls new files each time. The "seed" used to generate a seller_name is based on the seller_id, so the generated value remains consistent across runs.

### Data ingestion to Snowflake
Because the Olist dataset is static, the ingestion process is designed to load each source file once. Snowflake's `COPY INTO` command tracks previously loaded files and skips them on subsequent executions, allowing the ingestion script to be safely rerun without duplicating data.

For this static Olist dataset, rebuilding the project from scratch can be accomplished by downloading the source files again and recreating or clearing the Snowflake `RAW` tables and stage before rerunning the ingestion process.

## Design Decisions

### Why Python for ingestion?

Python provides a lightweight way to:

* Control the ingestion workflow
* Interact with Snowflake
* Provide logging and error handling
* Automate repeatable ingestion

Python provides an opportunity to gain experience with basic data ingestion processes separate from dbt's seed functionality for CSV files.

### Why Snowflake for the raw layer?

Snowflake provides scalable cloud storage and compute while allowing the raw source data to remain separate from the transformed analytical models.

### Why separate ingestion from dbt?

The ingestion layer and transformation layer have different responsibilities.

**Ingestion**

> Move data reliably from the source system into the warehouse.

**dbt**

> Transform, test, document, and model warehouse data for analytics.

Keeping these responsibilities separate makes the pipeline easier to troubleshoot and allows the dbt project to operate against a stable raw data layer.

## Related Documentation

See the main project README for an overview of the complete analytics pipeline.

The downstream dbt project contains the staging, transformation, testing, and analytical modeling layers.

# Appendix

## Additional example output from load_olist_to_snowflake.py

### All files already present
All source files have already been loaded. When the ingestion script is rerun, `COPY INTO` detects that the files have already been loaded and processes zero files.
```
2026-08-22 11:14:08,062  INFO     Snowflake Connector for Python Version: 4.7.2, Python Version: 3.14.7, Platform: Windows-11-10.0.26200-SP0
2026-08-22 11:14:08,062  INFO     Connecting to GLOBAL Snowflake domain
2026-08-22 11:14:11,830  INFO     Processing olist_customers_dataset.csv -> CUSTOMERS
2026-08-22 11:14:13,439  INFO     Processing olist_geolocation_dataset.csv -> GEOLOCATION
2026-08-22 11:14:14,287  INFO     Processing olist_order_items_dataset.csv -> ORDER_ITEMS
2026-08-22 11:14:14,996  INFO     Processing olist_order_payments_dataset.csv -> ORDER_PAYMENTS
2026-08-22 11:14:15,632  INFO     Processing olist_order_reviews_dataset.csv -> ORDER_REVIEWS
2026-08-22 11:14:16,983  INFO     Processing olist_orders_dataset.csv -> ORDERS
2026-08-22 11:14:17,681  INFO     Processing olist_products_dataset.csv -> PRODUCTS
2026-08-22 11:14:18,228  INFO     Processing olist_sellers_dataset.csv -> SELLERS
2026-08-22 11:14:18,945  INFO     Processing product_category_name_translation.csv -> PRODUCT_CATEGORY_NAME_TRANSLATION

Load Summary:
┌───────────────────────────────────────┬───────────────────────────────────┬───────────────────────────────────────┬───────────────┬───────────────┐
│ file                                  │ table                             │ status                                │   rows_parsed │   rows_loaded │
├───────────────────────────────────────┼───────────────────────────────────┼───────────────────────────────────────┼───────────────┼───────────────┤
│ olist_customers_dataset.csv           │ CUSTOMERS                         │ Copy executed with 0 files processed. │             0 │             0 │
│ olist_geolocation_dataset.csv         │ GEOLOCATION                       │ Copy executed with 0 files processed. │             0 │             0 │
│ olist_order_items_dataset.csv         │ ORDER_ITEMS                       │ Copy executed with 0 files processed. │             0 │             0 │
│ olist_order_payments_dataset.csv      │ ORDER_PAYMENTS                    │ Copy executed with 0 files processed. │             0 │             0 │
│ olist_order_reviews_dataset.csv       │ ORDER_REVIEWS                     │ Copy executed with 0 files processed. │             0 │             0 │
│ olist_orders_dataset.csv              │ ORDERS                            │ Copy executed with 0 files processed. │             0 │             0 │
│ olist_products_dataset.csv            │ PRODUCTS                          │ Copy executed with 0 files processed. │             0 │             0 │
│ olist_sellers_dataset.csv             │ SELLERS                           │ Copy executed with 0 files processed. │             0 │             0 │
│ product_category_name_translation.csv │ PRODUCT_CATEGORY_NAME_TRANSLATION │ Copy executed with 0 files processed. │             0 │             0 │
└───────────────────────────────────────┴───────────────────────────────────┴───────────────────────────────────────┴───────────────┴───────────────┘
```

### Some source files have already been loaded
Two source files have not yet been loaded, while the remaining files have already been processed. `COPY INTO` skips source files that have already been loaded and processes the files that have not yet been loaded.

```text
2026-08-22 11:15:50,032  INFO     Snowflake Connector for Python Version: 4.7.2, Python Version: 3.14.7, Platform: Windows-11-10.0.26200-SP0
2026-08-22 11:15:50,033  INFO     Connecting to GLOBAL Snowflake domain
2026-08-22 11:15:53,691  INFO     Processing olist_customers_dataset.csv -> CUSTOMERS
2026-08-22 11:15:54,621  INFO     Processing olist_geolocation_dataset.csv -> GEOLOCATION
2026-08-22 11:15:55,725  INFO     Processing olist_order_items_dataset.csv -> ORDER_ITEMS
2026-08-22 11:15:56,516  INFO     Processing olist_order_payments_dataset.csv -> ORDER_PAYMENTS
2026-08-22 11:15:57,252  INFO     Processing olist_order_reviews_dataset.csv -> ORDER_REVIEWS
2026-08-22 11:15:58,049  INFO     Processing olist_orders_dataset.csv -> ORDERS
2026-08-22 11:15:58,807  INFO     Processing olist_products_dataset.csv -> PRODUCTS
2026-08-22 11:15:59,491  INFO     Processing olist_sellers_dataset.csv -> SELLERS
2026-08-22 11:16:01,113  INFO     Processing product_category_name_translation.csv -> PRODUCT_CATEGORY_NAME_TRANSLATION

Load Summary:
┌───────────────────────────────────────┬───────────────────────────────────┬───────────────────────────────────────┬───────────────┬───────────────┐
│ file                                  │ table                             │ status                                │   rows_parsed │   rows_loaded │
├───────────────────────────────────────┼───────────────────────────────────┼───────────────────────────────────────┼───────────────┼───────────────┤
│ olist_customers_dataset.csv           │ CUSTOMERS                         │ Copy executed with 0 files processed. │             0 │             0 │
│ olist_geolocation_dataset.csv         │ GEOLOCATION                       │ Copy executed with 0 files processed. │             0 │             0 │
│ olist_order_items_dataset.csv         │ ORDER_ITEMS                       │ Copy executed with 0 files processed. │             0 │             0 │
│ olist_order_payments_dataset.csv      │ ORDER_PAYMENTS                    │ Copy executed with 0 files processed. │             0 │             0 │
│ olist_order_reviews_dataset.csv       │ ORDER_REVIEWS                     │ Copy executed with 0 files processed. │             0 │             0 │
│ olist_orders_dataset.csv              │ ORDERS                            │ Copy executed with 0 files processed. │             0 │             0 │
│ olist_products_dataset.csv            │ PRODUCTS                          │ Copy executed with 0 files processed. │             0 │             0 │
│ olist_sellers_dataset.csv             │ SELLERS                           │ LOADED                                │          3095 │          3095 │
│ product_category_name_translation.csv │ PRODUCT_CATEGORY_NAME_TRANSLATION │ LOADED                                │            71 │            71 │
└───────────────────────────────────────┴───────────────────────────────────┴───────────────────────────────────────┴───────────────┴───────────────┘
```