CREATE TABLE weather_stations (
    id                  INTEGER PRIMARY KEY,
    dwd_station_id       TEXT,
    wmo_station_id       TEXT,
    station_name         TEXT,
    observation_type     TEXT,
    lat                 DOUBLE PRECISION,
    lon                 DOUBLE PRECISION,
    height               DOUBLE PRECISION,
    distance             DOUBLE PRECISION,
    first_record         TIMESTAMPTZ,
    last_record          TIMESTAMPTZ,
    created_at           TIMESTAMPTZ DEFAULT now()
);

SELECT version();
CREATE EXTENSION postgis;
CREATE EXTENSION IF NOT EXISTS postgis;
SELECT PostGIS_Full_Version();
SET search_path TO raw, public;


CREATE TABLE IF NOT EXISTS raw.geo_plz (
  id        text PRIMARY KEY,
  plz       text NOT NULL,
  rel   text,
  geom      geometry(GEOMETRY, 4326) NOT null,
  geom_geojson text
);

CREATE INDEX IF NOT EXISTS raw_plz_geom_gix
  ON raw.geo_plz
  USING GIST (geom);

CREATE INDEX IF NOT EXISTS raw_plz_plz_idx
  ON raw.geo_plz (plz);

create schema if not exists stg;
create schema if not exists final;
 
CREATE TABLE raw.weather_observations (
    timestamp TEXT NOT NULL,
    source_id TEXT NOT NULL,

    cloud_cover TEXT,
    condition TEXT,
    dew_point TEXT,
    icon TEXT,
    pressure_msl TEXT,
    relative_humidity TEXT,
    temperature TEXT,
    visibility TEXT,

    fallback_source_ids TEXT,

    precipitation_10 TEXT,
    precipitation_30 TEXT,
    precipitation_60 TEXT,

    solar_10 TEXT,
    solar_30 TEXT,
    solar_60 TEXT,

    sunshine_30 TEXT,
    sunshine_60 TEXT,

    wind_direction_10 TEXT,
    wind_direction_30 TEXT,
    wind_direction_60 TEXT,

    wind_speed_10 TEXT,
    wind_speed_30 TEXT,
    wind_speed_60 TEXT,

    wind_gust_direction_10 TEXT,
    wind_gust_direction_30 TEXT,
    wind_gust_direction_60 TEXT,

    wind_gust_speed_10 TEXT,
    wind_gust_speed_30 TEXT,
    wind_gust_speed_60 TEXT,

    inserted_at TEXT,     -- set from your pipeline (iso string)
    updated_at TEXT,      -- set on upsert
    PRIMARY KEY (timestamp, source_id)
);

-- useful for time queries
CREATE INDEX ix_weather_observations_timestamp
ON weather_observations (timestamp);

 
 SELECT proname, nspname
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE proname = 'st_geomfromtext';

SELECT ST_GeomFromText(
  'POINT(13.399021 52.527014)',
  4326
);


SELECT raw.ST_GeomFromText(
  'POLYGON ((13.399021 52.527014, 13.398704 52.527014, 13.398704 52.526800, 13.399021 52.526800, 13.399021 52.527014))',
  4326
);