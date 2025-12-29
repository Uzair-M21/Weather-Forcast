import json
import sys
import requests
import logging
import psycopg2
from psycopg2.extras import execute_batch
from src.db import get_connection

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

weather_url = "https://api.brightsky.dev/weather"
stations_url = "https://api.brightsky.dev/sources"




def weather_stations_list():
    params = {
        "lat" : 52.502778,
        "lon" : 13.404167,
        "max_dist" : 25000
    }
    try:
        logger.info("Calling Station API")
        response = requests.get(stations_url,params=params, timeout=10)
        response.raise_for_status()

        station_raw_data = response.json().get("sources",[])
        if not station_raw_data:
             logger.warning("Api returned no data")
             return None

        stations = []
        for row in station_raw_data:
            station = {
                "id": row.get("id"),
                "dwd_station_id": row.get("dwd_station_id"),
                "observation_type": row.get("observation_type"),
                "lat": row.get("lat"),
                "lon": row.get("lon"),
                "height": row.get("height"),
                "station_name": row.get("station_name"),
                "wmo_station_id": row.get("wmo_station_id"),
                "first_record": row.get("first_record"),
                "last_record": row.get("last_record"),
                "distance": row.get("distance"),
            }
            stations.append(station)
        return stations
        ###print(json.dumps(stations,indent=4))

    except requests.exceptions.Timeout:
        logger.error("Request Timeout")
    except requests.exceptions.HTTPError as e:
        logger.error("HTTP error occured: %s",e)
        logger.error("Response body: %s",response.text)
    except Exception as e:
        logger.error("Unexpected Error: %s", e)

def upsert_stations(stations):
    sql = """
            INSERT INTO weather_stations (
                id,
                dwd_station_id,
                wmo_station_id,
                station_name,
                observation_type,
                lat,
                lon,
                height,
                distance,
                first_record,
                last_record
            )
            VALUES (
                %(id)s,
                %(dwd_station_id)s,
                %(wmo_station_id)s,
                %(station_name)s,
                %(observation_type)s,
                %(lat)s,
                %(lon)s,
                %(height)s,
                %(distance)s,
                %(first_record)s,
                %(last_record)s
            )
            ON CONFLICT (id) DO UPDATE
            SET
                dwd_station_id   = EXCLUDED.dwd_station_id,
                wmo_station_id   = EXCLUDED.wmo_station_id,
                station_name     = EXCLUDED.station_name,
                observation_type = EXCLUDED.observation_type,
                lat              = EXCLUDED.lat,
                lon              = EXCLUDED.lon,
                height           = EXCLUDED.height,
                distance         = EXCLUDED.distance,
                first_record     = EXCLUDED.first_record,
                last_record      = EXCLUDED.last_record;
        """
    conn = None
    try:
        logger.info("Connecting with db")
        conn = get_connection()
        with conn.cursor() as cur:
            execute_batch(cur, sql, stations,page_size=500)
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
    stations = weather_stations_list()
    if stations:
        upsert_stations(stations)

if __name__ == "__main__":
    main()
