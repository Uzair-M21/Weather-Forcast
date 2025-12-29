{{ config(materialized='view') }}

select
  plz,
  geom,
  area_m2,
  perimeter_m,
  centroid_lat,
  centroid_lon
from {{ ref('stg_geo_plz') }}
