# Weather Data Pipeline (Docker + Airflow + dbt + Postgres)

This project ingests weather data into a Postgres data warehouse and builds analytics-ready models using dbt.  
The resulting data models are designed for downstream usage such as dashboards and machine-learning pipelines.

---

## Architecture

### Layers

- **raw**  
  Persisted source payloads with fixed data types.

- **staging (dbt views)**  
  1:1 projections of raw tables with standardized naming, light normalization, and validation flags.

- **intermediate (dbt views/tables)**  
  ML-ready data shapes such as latest-per-station snapshots, consolidated metrics, and spatially prepared dimensions.

---

### Pipelines

- **Reference setup**  
  Loads station metadata and geo postal-code polygons.

- **Hourly ingestion**  
  Ingests current weather observations (and forecast data if enabled).

- **Transformation**  
  dbt models build staging and intermediate layers on top of raw data.

---

## Requirements

- Docker  
- Docker Compose  
- (Optional) `psql` or DBeaver for database inspection  
- (Optional) PostGIS enabled in Postgres if spatial joins are used

---

## Repository Structure

)

This project ingests weather data into a Postgres data warehouse and builds analytics-ready models using dbt.  
The resulting data models are designed for downstream usage such as dashboards and machine-learning pipelines.

---

## Architecture

### Layers

- **raw**  
  Persisted source payloads with fixed data types.

- **staging (dbt views)**  
  1:1 projections of raw tables with standardized naming, light normalization, and validation flags.

- **intermediate (dbt views/tables)**  
  ML-ready data shapes such as latest-per-station snapshots, consolidated metrics, and spatially prepared dimensions.

---

### Pipelines

- **Reference setup/daily ingestion**  
  Loads station metadata and geo postal-code polygons.

- **Hourly ingestion**  
  Ingests current weather observations (and forecast data if enabled).

- **Transformation**  
  dbt models build staging and intermediate layers on top of raw data.

---

## Requirements

- Docker  
- Docker Compose  
- (Optional) `psql` or DBeaver for database inspection  
- (Optional) PostGIS enabled in Postgres if spatial joins are used

---

## Repository Structure
```
├── docker-compose.yml
├── ingestion/ # Python ingestion modules / Docker image
├── airflow/ # Airflow DAGs
├── postgres/ # Postgres initialization (Create Statements - raw layer)
└── dbt/ # dbt project
    └── models/
        ├── staging/
        └── intermediate/
```
## Running the Application
