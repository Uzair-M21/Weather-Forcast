import os
import json
import geopandas as gpd
import brotli
import logging
from psycopg2.extras import execute_batch
import db


logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)

logger = logging.getLogger(__name__)

plz_file_comp = "postleitzahlen.geojson.br"
plz_file_decomp = "postleitzahlen.geojson"

def decompress_plz():

    try:
        logger.info("Decompressing Plz File")
        with open(plz_file_comp,"rb") as f:
            decompressed = brotli.decompress(f.read())
    except Exception as e:
        logger.error("Unable to decompress Plz.br file, Error : %s ",e)
        raise

    try:
        logger.info("Writing Plz File")
        with open(plz_file_decomp, "wb") as f:
            f.write(decompressed)
        logger.info("File Written Successfully")
    except Exception as e:
        logger.error("Failed to write Plz File, Error : %s ", e)
        raise

def delete_file():
    try:
        logger.info("Deleting File : %s",plz_file_decomp)
        os.remove(plz_file_decomp)
        logger.info("File Deleted")
    except Exception as e:
        logger.error("Unable to delete File, Error : %s",e)

def insert_geoplz():
    try:
        logger.info("Reading Plz File")
        gdf = gpd.read_file("postleitzahlen.geojson")
        logger.info("Restricting Postal Codes to Berlin")
        gdf["postcode_int"] = gdf["postcode"].astype(int)
        gdf=gdf[(gdf["postcode_int"] >= 10115) & (gdf["postcode_int"] <=14199)].drop(columns=["postcode_int"])
    except Exception as e:
        logging.error("Failed to Read File, Error : %s",e)
        raise

    geo_plz_data = [
        (r["id"], r["postcode"], r["rel"], r["geometry"].wkt, r["geometry"].wkt)
        for _, r in gdf.iterrows()
    ]


    sql = """
    INSERT INTO raw.geo_plz (id, plz, rel, geom,geom_geojson)
    VALUES (%s, %s, %s, raw.ST_GeomFromText(%s::text, 4326), raw.ST_AsGeoJSON(raw.ST_GeomFromText(%s::text, 4326)))
    ON CONFLICT (id) DO UPDATE
    SET plz      = EXCLUDED.plz,
        rel      = EXCLUDED.rel,
        geom     = EXCLUDED.geom,
        geom_geojson = EXCLUDED.geom_geojson;
    """

    conn = None
    try:
        logger.info("Connecting with db")
        conn = db.get_connection()
        with conn.cursor() as cur:
            execute_batch(cur, sql, geo_plz_data, page_size=500)
        conn.commit()
    except Exception as e:
        if conn:
            conn.rollback()
        logger.error("db error : %s", e)
    finally:
        if conn:
            conn.close()


def main():
    delete_file()
    decompress_plz()
    insert_geoplz()
    delete_file()


if __name__ == '__main__':
    main()

