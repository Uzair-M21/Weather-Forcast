{{ config(materialized='view')}}

select
  id::int                         as source_id,
  dwd_station_id                  as dwd_station_id,
  wmo_station_id                  as wmo_station_id,
  station_name                    as station_name,
  observation_type                as observation_type,
  lat                             as lat,
  lon                             as lon,
  height                          as height,
  distance                        as distance,
  first_record                    as first_record,
  last_record                     as last_record,
  created_at                      as created_at
from raw.weather_stations