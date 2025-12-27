{{ config(materialized='view')}}

select
  id::int                         as source_id,
  dwd_station_id                  as dwd_station_id,
  wmo_station_id                  as wmo_station_id,
  station_name                    as station_name,
  observation_type                as observation_type,
  lat::double precision           as lat,
  lon::double precision           as lon,
  height::double precision        as height,
  distance::double precision      as distance,
  first_record::timestamptz       as first_record,
  last_record::timestamptz        as last_record,
  created_at::timestamptz         as created_at
from raw.weather_stations