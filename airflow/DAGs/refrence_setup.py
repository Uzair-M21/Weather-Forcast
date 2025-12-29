import os
from datetime import datetime
from airflow import DAG
from airflow.providers.docker.operators.docker import DockerOperator
from docker.types import Mount
from airflow.utils.task_group import TaskGroup
from airflow.operators.python import PythonOperator
from airflow.models import Variable

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

def mark_reference_ready():
    Variable.set("REFERENCE_READY", "true")

with DAG(
    dag_id="reference_setup",
    start_date=datetime(2025, 12, 1),
    schedule="@daily",      # or set to None and trigger manually
    catchup=False,
    max_active_runs=1,
    tags=["reference","daily","station&plz"],
) as dag:

    with TaskGroup("ingest_reference_data") as ingest_reference_data:
        ingest_geo_plz = ingestion_task("ingest_geo_plz", "src.ingest_geo_plz")
        ingest_stations = ingestion_task("ingest_stations", "src.ingest_stations")

    dbt_reference_models = dbt_run_task(
        task_id="dbt_reference_models",
        select_models=[
            "stg_weather_stations_list",
            "stg_geo_plz",
            "int_weather_stations_list",
            "int_geo_plz",
            "int_berlin_weather_stations_plz",
        ],
    )

    set_ready_flag = PythonOperator(
        task_id="set_reference_ready_flag",
        python_callable=mark_reference_ready,
    )

    ingest_reference_data >> dbt_reference_models >> set_ready_flag