{{ config(materialized='view') }}

with stations as (
    select * ,
    ST_SetSRID(ST_MakePoint(lon, lat), 4326) as geom_point
    from
    {{ref('int_weather_stations_list')}}
),

plz as (
    select plz,
    geom as plz_geom
    from
    {{ref('int_geo_plz')}}
)

select
  s.dwd_station_id,
  s.wmo_station_id,
  s.station_name,
  s.observation_types,
  s.lat,
  s.lon,
  p.plz
from stations s
join plz p
  on ST_Within(s.geom_point, p.plz_geom)