{{ config(materialized='view') }}

select
    source_id                         as station_id,

    -- API valid time
    timestamp::timestamptz            as forecast_ts,

    -- typed weather values
    precipitation::numeric            as precipitation,
    pressure_msl::numeric             as pressure_msl,
    sunshine::numeric                 as sunshine,
    temperature::numeric              as temperature,

    wind_direction::integer           as wind_direction,
    wind_speed::numeric               as wind_speed,
    cloud_cover::integer              as cloud_cover,

    dew_point::numeric                as dew_point,
    relative_humidity::integer        as relative_humidity,
    visibility::integer               as visibility,

    wind_gust_direction::integer      as wind_gust_direction,
    wind_gust_speed::numeric          as wind_gust_speed,

    condition,
    precipitation_probability::numeric     as precipitation_probability,
    precipitation_probability_6h::numeric  as precipitation_probability_6h,
    solar::numeric                         as solar,

    -- nested json kept as jsonb
    fallback_source_ids::jsonb         as fallback_source_ids,

    icon,
    inserted_at

from raw.forecast_weather