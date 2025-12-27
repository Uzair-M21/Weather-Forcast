{{ config(materialized='view') }}

select
  plz,
  geom
from {{ ref('stg_geo_plz') }}
