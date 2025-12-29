{{ config(materialized='view') }}

select
  dwd_station_id,
  wmo_station_id,

  max(station_name) as station_name, --any value of station name, have spelling issues so cannot use aggregation
  string_agg(source_id::text, '|' order by source_id)               as source_ids,
  string_agg(distinct observation_type, '|' order by observation_type) as observation_types,

  avg(lat)        as lat,
  avg(lon)        as lon,
  avg(height)     as height,
  avg(distance)   as distance

from {{ ref('stg_weather_stations_list') }}
where dwd_station_id is not null
group by 1,2
