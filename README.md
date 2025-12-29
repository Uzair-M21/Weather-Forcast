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

1. **Download the source code**  
   Clone or download the repository to your local machine.

2. **Configure environment variables**  
   Update the `PROJECT_ROOT` variable in the `.env` file (located at the repository root) to point to the absolute path of the downloaded project directory.

3. **Start Docker**  
   Ensure Docker is running on your machine.

4. **Build and start services**  
   From the project root directory, run:
   ```
   docker compose up -d --build
    ```
5. **Access Airflow and Postgres**  
   - Open the Airflow UI to monitor DAG execution and logs.  
   - Connect to Postgres using any client (e.g., psql or DBeaver) to inspect ingested and transformed data.  
   - Use the credentials defined in the `.env` file.

6. **Trigger DAGs manually (if required)**  
   If the DAGs do not start automatically, trigger them manually in the following order:
   ```bash
   docker compose exec airflow-scheduler airflow dags trigger reference_setup
   docker compose exec airflow-scheduler airflow dags trigger weather_hourly
7. if the DAGs doesnot run automatically please run the following commands one by one
 ```
   docker compose exec airflow-scheduler airflow dags trigger reference_setup
   docker compose exec airflow-scheduler airflow dags trigger weather_hourly
   ```
