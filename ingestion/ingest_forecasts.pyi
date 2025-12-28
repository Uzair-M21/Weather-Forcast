import json
import logging
import db
from psycopg2.extras import execute_batch
import requests
import pandas as pd
from datetime import datetime, timezone, timedelta



logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)

logger = logging.getLogger(__name__)

forecast_weather_url = "https://api.brightsky.dev/weather"
current_weather_url = "https://api.brightsky.dev/current_weather"


forcast_window=72
# change this to forcast window
forecast_start_dt = datetime.now(timezone.utc).replace(minute=0, second=0, microsecond=0)
forecast_end_dt = forecast_start_dt + timedelta(hours=forcast_window)

forecast_start_time = forecast_start_dt.isoformat()
forecast_end_time = forecast_end_dt.isoformat()


def read_berlin_stations():
    sql = """
               SELECT dwd_station_id,wmo_station_id,station_name
               from dev_intermediate.int_berlin_weather_stations_plz
               where 
               observation_types like '%current%'
               or observation_types like '%synop%'
           """
    conn = None
    try:
        logger.info("Connecting with db")
        conn = db.get_connection()
        with conn.cursor() as cur:
            cur.execute(sql)
            rows=cur.fetchall()
            return rows
    except Exception as e:
        logger.error("db error : %s", e)
    finally:
        if conn:
            conn.close()

def get_forecast_weather(berlin_stations):
    all_station_forecast_weather = []
    for stations in berlin_stations:
        if stations[0] is None:
            continue
        params={
            "date":forecast_start_time,
            "dwd_station_id": stations[0],
            "last_date":forecast_end_time
        }
        try:
            logger.info("%s Hour forecast Weather for Stations %s",forcast_window,stations[0])
            response = requests.get(forecast_weather_url, params=params, timeout=10)
            response.raise_for_status()

            station_forecast_weather_raw = response.json().get("weather", [])
            if not station_forecast_weather_raw:
                logger.warning("Api returned no data")
                continue
            station_forecast_weather=[]
            for row in station_forecast_weather_raw:
                forecast_weather = {
                        "timestamp": row.get("timestamp"),
                        "source_id": row.get("source_id"),
                        "precipitation": row.get("precipitation"),
                        "pressure_msl": row.get("pressure_msl"),
                        "sunshine": row.get("sunshine"),
                        "temperature": row.get("temperature"),
                        "wind_direction": row.get("wind_direction"),
                        "wind_speed": row.get("wind_speed"),
                        "cloud_cover": row.get("cloud_cover"),
                        "dew_point": row.get("dew_point"),
                        "relative_humidity": row.get("relative_humidity"),
                        "visibility": row.get("visibility"),
                        "wind_gust_direction": row.get("wind_gust_direction"),
                        "wind_gust_speed": row.get("wind_gust_speed"),
                        "condition": row.get("condition"),
                        "precipitation_probability": row.get("precipitation_probability"),
                        "precipitation_probability_6h": row.get("precipitation_probability_6h"),
                        "solar": row.get("solar"),

                        # nested object kept as it is (convert to json later if needed)
                        "fallback_source_ids": json.dumps(row.get("fallback_source_ids") or {}),

                        "icon": row.get("icon"),
                }
                station_forecast_weather.append(forecast_weather)
            all_station_forecast_weather.extend(station_forecast_weather)
        except requests.exceptions.Timeout:
            logger.error("Request Timeout")
        except requests.exceptions.HTTPError as e:
            logger.error("HTTP error occurred: %s", e)
            logger.error("Response body: %s", response.text)
        except Exception as e:
            logger.error("Unexpected Error: %s", e)

    now = datetime.now(timezone.utc).isoformat()

    for row in all_station_forecast_weather:
        row["inserted_at"] = now
    return all_station_forecast_weather

def insert_forecast_weather(all_station_forecast_weather):
    sql = """
            INSERT INTO raw.forecast_weather_raw (
                source_id,
                timestamp,
            
                precipitation,
                pressure_msl,
                sunshine,
                temperature,
                wind_direction,
                wind_speed,
                cloud_cover,
                dew_point,
                relative_humidity,
                visibility,
                wind_gust_direction,
                wind_gust_speed,
                condition,
                precipitation_probability,
                precipitation_probability_6h,
                solar,
            
                fallback_source_ids,
            
                icon,
                inserted_at
            )
            VALUES (
                %(source_id)s,
                %(timestamp)s,
            
                %(precipitation)s,
                %(pressure_msl)s,
                %(sunshine)s,
                %(temperature)s,
                %(wind_direction)s,
                %(wind_speed)s,
                %(cloud_cover)s,
                %(dew_point)s,
                %(relative_humidity)s,
                %(visibility)s,
                %(wind_gust_direction)s,
                %(wind_gust_speed)s,
                %(condition)s,
                %(precipitation_probability)s,
                %(precipitation_probability_6h)s,
                %(solar)s,
            
                %(fallback_source_ids)s,
            
                %(icon)s,
                %(inserted_at)s
            );
    """
    conn = None
    try:
        logger.info("Connecting with db")
        conn = db.get_connection()
        with conn.cursor() as cur:
            execute_batch(cur, sql, all_station_forecast_weather,page_size=500)
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
    all_station_forecast_weather = get_forecast_weather(berlin_stations)
    insert_forecast_weather(all_station_forecast_weather)
def main2():
    print("hello")
if __name__ == '__main__':
    main2()

