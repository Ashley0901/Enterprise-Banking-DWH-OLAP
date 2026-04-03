# Enterprise Banking Data Warehouse (OLAP) 

##  Project Overview
This project presents a comprehensive, end-to-end Data Warehouse architecture designed for a banking institution. The objective is to analyze historical banking data (clients, accounts, transactions, fraud, and claims) to extract actionable business insights such as customer retention risks, transaction profitability, and channel usage trends.

The architecture employs a **Dual-Engine approach**:
1. A strongly normalized **Snowflake Schema** implemented in **PostgreSQL** for structured, relational analytical processing.
2. A specialized **Columnar Database** implemented in **ClickHouse** (via Docker) to demonstrate high-speed aggregations and big data optimizations for OLAP workloads.

##  Tech Stack & Tools
* **Core Databases:** PostgreSQL, ClickHouse
* **Infrastructure:** Docker
* **Data Modeling:** Snowflake Schema (3NF Dimensions)
* **Business Intelligence:** Qlik (Dashboards & Visualizations)
* **Languages:** Advanced SQL (CTEs, Window Functions, ClickHouse Analytical Functions)

##  Architecture & Data Modeling
The core of this project is a **Snowflake Schema** designed to minimize data redundancy while maintaining analytical query performance. 

* **Fact Tables:** `hechos_transaccionales`, `hechos_reclamos`, `hechos_fraude`.
* **Dimensions:** Heavily normalized into granular levels (e.g., *Location* is split into `ciudad` -> `estado` -> `pais`).


##  Key Features & Implementation

### 1. Advanced Analytical Queries (PostgreSQL)
Complex queries using Common Table Expressions (CTEs), Window Functions (`NTILE`, `OVER`), and conditional aggregations to solve real-world business questions:
* Identifying High-Value Clients for new product targeting.
* Analyzing seasonal transaction patterns.
* Evaluating customer behavior by transaction channel.

### 2. Columnar OLAP Optimization (ClickHouse)
To demonstrate scalability for big data, a subset of the architecture was implemented using **ClickHouse** containerized in **Docker**.
* Utilized the `MergeTree()` engine for rapid data ingestion and querying.
* Optimized memory usage with `LowCardinality()` for repetitive string/ID columns.
* Leveraged ClickHouse-specific functions (e.g., `arrayStringConcat`, `groupArrayDistinct`, `stddevSamp`) for high-speed anomaly detection and data grouping.

### 3. Business Intelligence Dashboards
The data was ingested into **Qlik** to create interactive dashboards, allowing stakeholders to visualize KPIs, fraud metrics, and transaction seasonality. *(See the implementation report in the docs folder for screenshots).*

##  Repository Structure

```text
├── sql_scripts/
│   ├── snowflake_schema_ddl.sql     # PostgreSQL database creation and schema
│   ├── analytical_queries.sql       # Complex business queries in PostgreSQL
│   ├── columnar_ddl.sql  # ClickHouse schema with MergeTree optimization
│   ├── columnar_queries.sql       # ClickHouse-specific high-speed queries
├── docs/
│   ├── Data_Warehouse_SnowFlake_Schema.png       # Visual ERD
│   ├── Snowflake_Schema_Relational_Model.pdf     # Schema mapping & dictionary
│   ├── OLAP_Implementation_and_BI_Dashboards.pdf # Full project report, Docker setup & Qlik Dashboards
└── README.md
