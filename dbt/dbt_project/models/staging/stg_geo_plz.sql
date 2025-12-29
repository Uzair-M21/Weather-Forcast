{{ config(materialized='view') }}

select
  id                             as id,
  lpad(trim(plz::text), 5, '0')  as plz,
  rel                            as osm_relation_id,
  geom                           as geom,
  geom_geojson                   as geom_geojson,
  st_area(geom::geography) as area_m2,
  st_perimeter(geom::geography) as perimeter_m,
  st_y(st_centroid(geom)) as centroid_lat,
  st_x(st_centroid(geom)) as centroid_lon
from raw.geo_plz
