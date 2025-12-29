import os
from datetime import datetime
from airflow import DAG
from airflow.sensors.python import PythonSensor
from docker.types import Mount
from airflow.models import Variable
from airflow.providers.docker.operators.docker import DockerOperator
from airflow.utils.task_group import TaskGroup

def req(name: str) -> str:
    v = os.getenv(name)
    if not v:
        raise RuntimeError(f"Missing required env var: {name}")
    return v

DB_ENV = {
    "DB_HOST": req("DB_HOST"),
    "DB_PORT": req("DB_PORT"),
    "DB_NAME": req("DB_NAME"),
    "DB_USER": req("DB_USER"),
    "DB_PASSWORD": req("DB_PASSWORD"),
}


# MUST be an absolute path on the host machine to your repo dbt folder,
# Please change this in the .env file in the root folder
# please change this variable according to your machine on which you downloaded/extracted the project

DBT_HOST_DIR = os.environ["DBT_HOST_DIR"]

INGESTION_IMAGE = "weather-ingestion:latest"
DBT_IMAGE = "ghcr.io/dbt-labs/dbt-postgres:1.8.2"
DOCKER_URL = "unix://var/run/docker.sock"
NETWORK_MODE = "app_net"
def ingestion_task(task_id: str, module: str) -> DockerOperator:
    return DockerOperator(
        task_id=task_id,
        image=INGESTION_IMAGE,
        command=f"python -m {module}",
        docker_url=DOCKER_URL,
        network_mode=NETWORK_MODE,
        auto_remove=True,
        environment=DB_ENV,
        mount_tmp_dir=False,
    )

def dbt_run_task(task_id: str, select_models: list[str]) -> DockerOperator:
    select_arg = " ".join(select_models)
    return DockerOperator(
        task_id=task_id,
        image=DBT_IMAGE,
        command=f"run --project-dir /dbt --profiles-dir /dbt --select {select_arg}",
        docker_url=DOCKER_URL,
        network_mode=NETWORK_MODE,
        auto_remove=True,
        mounts=[Mount(source=DBT_HOST_DIR, target="/dbt", type="bind")],
        environment=DB_ENV,
        mount_tmp_dir=False,
    )

def reference_is_ready() -> bool:
    return Variable.get("REFERENCE_READY", default_var="false").lower() == "true"

with DAG(
    dag_id="weather_hourly",
    start_date=datetime(2025, 12, 1),
    schedule="15 * * * *",
    catchup=False,
    max_active_runs=1,
    tags=["hourly", "weather"],
) as dag:

    wait_for_reference = PythonSensor(
        task_id="wait_for_reference_setup",
        python_callable=reference_is_ready,
        mode="reschedule",
        poke_interval=60,
        timeout=60 * 60 * 1,  # wait up to 1h
    )

    with TaskGroup("ingest_weather_data") as ingest_weather_data:
        ingest_forecasts = ingestion_task("ingest_forecasts", "src.ingest_forecasts")
        ingest_observations = ingestion_task("ingest_observations", "src.ingest_observations")

    dbt_weather_models = dbt_run_task(
        task_id="dbt_weather_models",
        select_models=[
            "stg_forecast_weather",
            "stg_current_weather_observations",
            "int_latest_current_weather_observations",
            "int_forecast_weather_scd2",
        ],
    )

    wait_for_reference >> ingest_weather_data >> dbt_weather_models