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

CREATE TABLE IF NOT EXISTS raw.geo_plz (
  id        text PRIMARY KEY,
  plz       text NOT NULL,
  rel   text,
  geom      geometry(GEOMETRY, 4326) NOT null,
  geom_geojson jsonb
);

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




