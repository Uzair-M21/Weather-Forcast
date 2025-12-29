{{ config(materialized='view') }}

select
    source_id                         as station_id,
    timestamp::timestamptz            as forecast_ts,

    precipitation           as precipitation,
    pressure_msl            as pressure_msl,
    sunshine                as sunshine,
    temperature             as temperature,

    wind_direction           as wind_direction,
    wind_speed              as wind_speed,
    cloud_cover              as cloud_cover,

    dew_point               as dew_point,
    relative_humidity        as relative_humidity,
    visibility               as visibility,

    wind_gust_direction      as wind_gust_direction,
    wind_gust_speed         as wind_gust_speed,

    condition,
    precipitation_probability    as precipitation_probability,
    precipitation_probability_6h as precipitation_probability_6h,
    solar                        as solar,

    -- nested json
    fallback_source_ids::jsonb         as fallback_source_ids,

    icon,
    inserted_at,

    ----- Validation flags

    (temperature is null or temperature between -80 and 60) as is_valid_temperature,
    (relative_humidity is null or relative_humidity between 0 and 100) as is_valid_relative_humidity,
    (pressure_msl is null or pressure_msl between 800 and 1100) as is_valid_pressure_msl,

    (precipitation is null or precipitation >= 0) as is_valid_precipitation,
    (visibility is null or visibility >= 0) as is_valid_visibility,

    (wind_speed is null or wind_speed >= 0) as is_valid_wind_speed,
    (wind_gust_speed is null or wind_gust_speed >= 0) as is_valid_wind_gust_speed,

    (wind_direction is null or wind_direction between 0 and 360) as is_valid_wind_direction,
    (wind_gust_direction is null or wind_gust_direction between 0 and 360) as is_valid_wind_gust_direction,

    (cloud_cover is null or cloud_cover between 0 and 100) as is_valid_cloud_cover,
    (dew_point is null or dew_point between -100 and 60) as is_valid_dew_point,

    (sunshine is null or sunshine >= 0) as is_valid_sunshine,

    (precipitation_probability is null or precipitation_probability between 0 and 100) as is_valid_precipitation_probability,
    (precipitation_probability_6h is null or precipitation_probability_6h between 0 and 100) as is_valid_precipitation_probability_6h,

    (solar is null or solar >= 0) as is_valid_solar,

    -- is all flags valid --
    (
      (temperature is null or temperature between -80 and 60)
      and (relative_humidity is null or relative_humidity between 0 and 100)
      and (pressure_msl is null or pressure_msl between 800 and 1100)
      and (precipitation is null or precipitation >= 0)
      and (visibility is null or visibility >= 0)
    ) as is_all_flag_valid

from raw.forecast_weather