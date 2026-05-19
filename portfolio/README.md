# Data Engineering Portfolio

## Overview
A collection of data marts and ETL pipelines built with PostgreSQL and Apache Airflow, 
based on real e-commerce data.

## Tech Stack
- **SQL** — PostgreSQL, window functions, CTEs, JSON processing
- **Airflow** — DAG orchestration, scheduled pipelines, parallel tasks
- **Python** — pandas, gspread, psycopg2

## Data Marts

### customer_mart
Customer analytics mart with incremental loading (DELETE + INSERT pattern).
- 4 data sources joined in a single pipeline
- JSON data processing from raw tables
- Document history stored as JSONB arrays
- Phone/email confirmation flags based on auth methods

### crm_mart
CRM communication efficiency mart with cost allocation.
- SMS and email unified in one mart
- Cost data loaded from Google Sheets via Python
- Quarterly price allocation per provider and tariff

### ym_mart
Yandex Metrica web analytics mart.
- Array unnesting for hit-visit joining
- URL parsing and page classification
- Event type prioritization logic

### cjm
Customer Journey Map mart.
- 6 parallel Airflow tasks, one per data source
- Incremental loading with per-source timestamps
- Events from registrations, authorizations, orders, CRM

### retention_mart
Cohort retention analysis mart.
- Monthly cohort calculation
- Retention rate per cohort and month offset

## Pipeline Architecture
Each mart has a dedicated Airflow DAG with scheduled updates ranging from hourly 
to daily depending on business requirements.
