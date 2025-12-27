{{ config(materialized='view') }}

select
  id                         as id,
  plz                        as plz,
  rel                        as osm_relation_id,
  geom                       as geom,
  geom_geojson               as geom_geojson
from raw.geo_plz
