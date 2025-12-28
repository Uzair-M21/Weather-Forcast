CREATE INDEX IF NOT EXISTS raw_plz_geom_gix
  ON raw.geo_plz
  USING GIST (geom);

CREATE INDEX IF NOT EXISTS raw_plz_plz_idx
  ON raw.geo_plz (plz);

  CREATE INDEX ix_weather_observations_timestamp
ON weather_observations (timestamp);

create index if not exists idx_forecast_raw_lookup
on raw.forecast_weather (source_id, timestamp, inserted_at desc);
