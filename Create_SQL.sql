CREATE TABLE raw.weather_stations (
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
  geom_geojson jsonb
);

CREATE INDEX IF NOT EXISTS raw_plz_geom_gix
  ON raw.geo_plz
  USING GIST (geom);

CREATE INDEX IF NOT EXISTS raw_plz_plz_idx
  ON raw.geo_plz (plz);


 
CREATE TABLE IF NOT EXISTS raw.weather_observations (
    timestamp timestamptz NOT NULL,
    source_id text NOT NULL,

    cloud_cover double precision,
    condition text,
    dew_point double precision,
    icon text,
    pressure_msl double precision,
    relative_humidity double precision,
    temperature double precision,
    visibility double precision,

    fallback_source_ids jsonb,

    precipitation_10 double precision,
    precipitation_30 double precision,
    precipitation_60 double precision,

    solar_10 double precision,
    solar_30 double precision,
    solar_60 double precision,

    sunshine_30 double precision,
    sunshine_60 double precision,

    wind_direction_10 double precision,
    wind_direction_30 double precision,
    wind_direction_60 double precision,

    wind_speed_10 double precision,
    wind_speed_30 double precision,
    wind_speed_60 double precision,

    wind_gust_direction_10 double precision,
    wind_gust_direction_30 double precision,
    wind_gust_direction_60 double precision,

    wind_gust_speed_10 double precision,
    wind_gust_speed_30 double precision,
    wind_gust_speed_60 double precision,

    inserted_at timestamptz NOT NULL DEFAULT now(),
    updated_at  timestamptz NOT NULL DEFAULT now(),

    PRIMARY KEY (timestamp, source_id)
);



-- useful for time queries
CREATE INDEX ix_weather_observations_timestamp
ON weather_observations (timestamp);

CREATE TABLE IF NOT EXISTS raw.forecast_weather (
    source_id                     text NOT NULL,
    timestamp                     timestamptz NOT NULL,

    precipitation                 double precision,
    pressure_msl                  double precision,
    sunshine                      double precision,
    temperature                   double precision,
    wind_direction                double precision,
    wind_speed                    double precision,
    cloud_cover                   double precision,
    dew_point                     double precision,
    relative_humidity             double precision,
    visibility                    double precision,
    wind_gust_direction           double precision,
    wind_gust_speed               double precision,
    condition                     text,
    precipitation_probability     double precision,
    precipitation_probability_6h  double precision,
    solar                         double precision,
    fallback_source_ids           jsonb,
    icon                          text,

    inserted_at                   timestamptz NOT NULL DEFAULT now()
);


create index if not exists idx_forecast_raw_lookup
on raw.forecast_weather (source_id, timestamp, inserted_at desc);


 
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

SELECT dwd_station_id,wmo_station_id,station_name
               from dev_intermediate.int_berlin_weather_stations_plz
               where 
               dwd_station_id is not null and(
               observation_types like '%current%'
               or observation_types like '%synop%')