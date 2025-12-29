{{ config(materialized='view') }}

select
  id                             as id,
  lpad(trim(plz::text), 5, '0')  as plz,
  rel                            as osm_relation_id,
  geom                           as geom,
  geom_geojson                   as geom_geojson,
  round(st_area(geom::geography)::numeric, 2)      as area_m2,
  round(st_perimeter(geom::geography)::numeric, 2) as perimeter_m,
  round(st_y(st_centroid(geom))::numeric, 6)       as centroid_lat,
  round(st_x(st_centroid(geom))::numeric, 6)       as centroid_lon
from raw.geo_plz
