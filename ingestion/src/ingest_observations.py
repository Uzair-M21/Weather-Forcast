import json
import logging
import sys
from src.db import get_connection
import psycopg2
from psycopg2.extras import execute_batch
import requests
import pandas as pd
from datetime import datetime, timezone



logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)

logger = logging.getLogger(__name__)

weather_url = "https://api.brightsky.dev/weather"
current_weather_url = "https://api.brightsky.dev/current_weather"

def read_berlin_stations():
    sql = """
               SELECT dwd_station_id,wmo_station_id,station_name
               from dev_intermediate.int_berlin_weather_stations_plz
               where 
               dwd_station_id is not null and(
               observation_types like '%current%'
               or observation_types like '%synop%')
           """
    conn = None
    try:
        logger.info("Connecting with db")
        conn = get_connection()
        with conn.cursor() as cur:
            logger.info("Fetching Berlin's Station list ")
            cur.execute(sql)
            rows=cur.fetchall()
            return rows
    except Exception as e:
        logger.error("db error : %s", e)
    finally:
        if conn:
            conn.close()


def get_current_weather(berlin_stations):
    all_station_current_weather = []
    for stations in berlin_stations:
        if stations[0] is None:
            continue
        params={
            "dwd_station_id": stations[0]
        }
        try:
            logger.info("Getting Current Weather for Stations %s",stations[0])
            response = requests.get(current_weather_url, params=params, timeout=10)
            response.raise_for_status()

            current_weather_raw = response.json().get("weather", {})
            if not current_weather_raw:
                logger.warning("Api returned no data")
                continue

            current_weather = {
                "timestamp": current_weather_raw.get("timestamp"),
                "source_id": current_weather_raw.get("source_id"),

                "cloud_cover": current_weather_raw.get("cloud_cover"),
                "condition": current_weather_raw.get("condition"),
                "dew_point": current_weather_raw.get("dew_point"),
                "icon": current_weather_raw.get("icon"),
                "pressure_msl": current_weather_raw.get("pressure_msl"),
                "relative_humidity": current_weather_raw.get("relative_humidity"),
                "temperature": current_weather_raw.get("temperature"),
                "visibility": current_weather_raw.get("visibility"),

                # nested object kept as-is (stringify later if needed)
                "fallback_source_ids": current_weather_raw.get("fallback_source_ids"),

                "precipitation_10": current_weather_raw.get("precipitation_10"),
                "precipitation_30": current_weather_raw.get("precipitation_30"),
                "precipitation_60": current_weather_raw.get("precipitation_60"),

                "solar_10": current_weather_raw.get("solar_10"),
                "solar_30": current_weather_raw.get("solar_30"),
                "solar_60": current_weather_raw.get("solar_60"),

                "sunshine_30": current_weather_raw.get("sunshine_30"),
                "sunshine_60": current_weather_raw.get("sunshine_60"),

                "wind_direction_10": current_weather_raw.get("wind_direction_10"),
                "wind_direction_30": current_weather_raw.get("wind_direction_30"),
                "wind_direction_60": current_weather_raw.get("wind_direction_60"),

                "wind_speed_10": current_weather_raw.get("wind_speed_10"),
                "wind_speed_30": current_weather_raw.get("wind_speed_30"),
                "wind_speed_60": current_weather_raw.get("wind_speed_60"),

                "wind_gust_direction_10": current_weather_raw.get("wind_gust_direction_10"),
                "wind_gust_direction_30": current_weather_raw.get("wind_gust_direction_30"),
                "wind_gust_direction_60": current_weather_raw.get("wind_gust_direction_60"),

                "wind_gust_speed_10": current_weather_raw.get("wind_gust_speed_10"),
                "wind_gust_speed_30": current_weather_raw.get("wind_gust_speed_30"),
                "wind_gust_speed_60": current_weather_raw.get("wind_gust_speed_60"),
            }

            all_station_current_weather.append(current_weather)

        except requests.exceptions.Timeout:
            logger.error("Request Timeout")
        except requests.exceptions.HTTPError as e:
            logger.error("HTTP error occured: %s", e)
            logger.error("Response body: %s", response.text)
        except Exception as e:
            logger.error("Unexpected Error: %s", e)

    return all_station_current_weather

    """now = datetime.now(timezone.utc).isoformat()

       for row in all_station_current_weather:
            row["inserted_at"] = now
            row["updated_at"] = now
        return all_station_current_weather
        """

def upsert_current_weather(all_station_current_weather):
    sql = """
        INSERT INTO raw.weather_observations (
            timestamp,
            source_id,

            cloud_cover,
            condition,
            dew_point,
            icon,
            pressure_msl,
            relative_humidity,
            temperature,
            visibility,

            fallback_source_ids,

            precipitation_10,
            precipitation_30,
            precipitation_60,

            solar_10,
            solar_30,
            solar_60,

            sunshine_30,
            sunshine_60,

            wind_direction_10,
            wind_direction_30,
            wind_direction_60,

            wind_speed_10,
            wind_speed_30,
            wind_speed_60,

            wind_gust_direction_10,
            wind_gust_direction_30,
            wind_gust_direction_60,

            wind_gust_speed_10,
            wind_gust_speed_30,
            wind_gust_speed_60
        )
        VALUES (
            %(timestamp)s,
            %(source_id)s,

            %(cloud_cover)s,
            %(condition)s,
            %(dew_point)s,
            %(icon)s,
            %(pressure_msl)s,
            %(relative_humidity)s,
            %(temperature)s,
            %(visibility)s,

            %(fallback_source_ids)s,

            %(precipitation_10)s,
            %(precipitation_30)s,
            %(precipitation_60)s,

            %(solar_10)s,
            %(solar_30)s,
            %(solar_60)s,

            %(sunshine_30)s,
            %(sunshine_60)s,

            %(wind_direction_10)s,
            %(wind_direction_30)s,
            %(wind_direction_60)s,

            %(wind_speed_10)s,
            %(wind_speed_30)s,
            %(wind_speed_60)s,

            %(wind_gust_direction_10)s,
            %(wind_gust_direction_30)s,
            %(wind_gust_direction_60)s,

            %(wind_gust_speed_10)s,
            %(wind_gust_speed_30)s,
            %(wind_gust_speed_60)s
        )
        ON CONFLICT (timestamp, source_id) DO UPDATE
        SET
            cloud_cover = EXCLUDED.cloud_cover,
            condition = EXCLUDED.condition,
            dew_point = EXCLUDED.dew_point,
            icon = EXCLUDED.icon,
            pressure_msl = EXCLUDED.pressure_msl,
            relative_humidity = EXCLUDED.relative_humidity,
            temperature = EXCLUDED.temperature,
            visibility = EXCLUDED.visibility,

            fallback_source_ids = EXCLUDED.fallback_source_ids,

            precipitation_10 = EXCLUDED.precipitation_10,
            precipitation_30 = EXCLUDED.precipitation_30,
            precipitation_60 = EXCLUDED.precipitation_60,

            solar_10 = EXCLUDED.solar_10,
            solar_30 = EXCLUDED.solar_30,
            solar_60 = EXCLUDED.solar_60,

            sunshine_30 = EXCLUDED.sunshine_30,
            sunshine_60 = EXCLUDED.sunshine_60,

            wind_direction_10 = EXCLUDED.wind_direction_10,
            wind_direction_30 = EXCLUDED.wind_direction_30,
            wind_direction_60 = EXCLUDED.wind_direction_60,

            wind_speed_10 = EXCLUDED.wind_speed_10,
            wind_speed_30 = EXCLUDED.wind_speed_30,
            wind_speed_60 = EXCLUDED.wind_speed_60,

            wind_gust_direction_10 = EXCLUDED.wind_gust_direction_10,
            wind_gust_direction_30 = EXCLUDED.wind_gust_direction_30,
            wind_gust_direction_60 = EXCLUDED.wind_gust_direction_60,

            wind_gust_speed_10 = EXCLUDED.wind_gust_speed_10,
            wind_gust_speed_30 = EXCLUDED.wind_gust_speed_30,
            wind_gust_speed_60 = EXCLUDED.wind_gust_speed_60,

            updated_at = now();
    """
    conn = None
    try:
        logger.info("Connecting with db")
        conn = get_connection()
        with conn.cursor() as cur:
            execute_batch(cur, sql, all_station_current_weather,page_size=500)
        conn.commit()
        logger.info("data inserted into db")
    except Exception as e:
        if conn:
            conn.rollback()
        logger.error("db error : %s",e)
    finally:
        if conn:
            conn.close()

def main():
    berlin_stations = read_berlin_stations()
    all_station_current_weather = get_current_weather(berlin_stations)
    upsert_current_weather(all_station_current_weather)

if __name__ == '__main__':
    main()
