    {{ config(materialized='view') }}
select
    "timestamp"::timestamptz        as "timestamp",
    source_id                       as station_id,

    cloud_cover                     as cloud_cover,
    "condition"                     as "condition",
    dew_point                        as dew_point,
    icon                             as icon,
    pressure_msl                     as pressure_msl,
    relative_humidity                as relative_humidity,
    temperature                      as temperature,
    visibility                       as visibility,
    fallback_source_ids::jsonb       as fallback_source_ids,

    precipitation_10                 as precipitation_10,
    precipitation_30                 as precipitation_30,
    precipitation_60                 as precipitation_60,

    solar_10                         as solar_10,
    solar_30                         as solar_30,
    solar_60                         as solar_60,

    sunshine_30                      as sunshine_30,
    sunshine_60                      as sunshine_60,

    wind_direction_10                as wind_direction_10,
    wind_direction_30                as wind_direction_30,
    wind_direction_60                as wind_direction_60,

    wind_speed_10                    as wind_speed_10,
    wind_speed_30                    as wind_speed_30,
    wind_speed_60                    as wind_speed_60,

    wind_gust_direction_10           as wind_gust_direction_10,
    wind_gust_direction_30           as wind_gust_direction_30,
    wind_gust_direction_60           as wind_gust_direction_60,

    wind_gust_speed_10               as wind_gust_speed_10,
    wind_gust_speed_30               as wind_gust_speed_30,
    wind_gust_speed_60               as wind_gust_speed_60,

    inserted_at                      as inserted_at,
    updated_at                       as updated_at,

   ----- Validation flags

    (temperature is null or temperature between -80 and 60)          as is_valid_temperature,
    (dew_point is null or dew_point between -100 and 60)             as is_valid_dew_point,
    (relative_humidity is null or relative_humidity between 0 and 100) as is_valid_relative_humidity,
    (pressure_msl is null or pressure_msl between 800 and 1100)      as is_valid_pressure_msl,
    (visibility is null or visibility >= 0)                          as is_valid_visibility,
    (cloud_cover is null or cloud_cover between 0 and 100)           as is_valid_cloud_cover,

    (precipitation_10 is null or precipitation_10 >= 0)              as is_valid_precipitation_10,
    (precipitation_30 is null or precipitation_30 >= 0)              as is_valid_precipitation_30,
    (precipitation_60 is null or precipitation_60 >= 0)              as is_valid_precipitation_60,

    (solar_10 is null or solar_10 >= 0)                              as is_valid_solar_10,
    (solar_30 is null or solar_30 >= 0)                              as is_valid_solar_30,
    (solar_60 is null or solar_60 >= 0)                              as is_valid_solar_60,

    (sunshine_30 is null or sunshine_30 >= 0)                        as is_valid_sunshine_30,
    (sunshine_60 is null or sunshine_60 >= 0)                        as is_valid_sunshine_60,

    (wind_direction_10 is null or wind_direction_10 between 0 and 360) as is_valid_wind_direction_10,
    (wind_direction_30 is null or wind_direction_30 between 0 and 360) as is_valid_wind_direction_30,
    (wind_direction_60 is null or wind_direction_60 between 0 and 360) as is_valid_wind_direction_60,

    (wind_speed_10 is null or wind_speed_10 >= 0)                    as is_valid_wind_speed_10,
    (wind_speed_30 is null or wind_speed_30 >= 0)                    as is_valid_wind_speed_30,
    (wind_speed_60 is null or wind_speed_60 >= 0)                    as is_valid_wind_speed_60,

    (wind_gust_direction_10 is null or wind_gust_direction_10 between 0 and 360) as is_valid_wind_gust_direction_10,
    (wind_gust_direction_30 is null or wind_gust_direction_30 between 0 and 360) as is_valid_wind_gust_direction_30,
    (wind_gust_direction_60 is null or wind_gust_direction_60 between 0 and 360) as is_valid_wind_gust_direction_60,

    (wind_gust_speed_10 is null or wind_gust_speed_10 >= 0)          as is_valid_wind_gust_speed_10,
    (wind_gust_speed_30 is null or wind_gust_speed_30 >= 0)          as is_valid_wind_gust_speed_30,
    (wind_gust_speed_60 is null or wind_gust_speed_60 >= 0)          as is_valid_wind_gust_speed_60,

     -- is all flags valid --

    (
        (temperature is null or temperature between -80 and 60)
        and (relative_humidity is null or relative_humidity between 0 and 100)
        and (pressure_msl is null or pressure_msl between 800 and 1100)
        and ("timestamp"::timestamptz <= now() + interval '10 minutes') --this is current weather so the weather should not be of future
    ) as is_all_flag_valid

from raw.current_weather_observations