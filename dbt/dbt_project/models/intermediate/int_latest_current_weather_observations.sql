with consolidated as (

    select
        "timestamp",
        source_id,

        cloud_cover,
        nullif(trim(condition), '') as condition,
        dew_point,
        nullif(trim(icon), '')      as icon,
        pressure_msl,
        relative_humidity,
        temperature,
        visibility,

        fallback_source_ids,
        inserted_at,
        updated_at,

        coalesce(precipitation_10, precipitation_30, precipitation_60) as precipitation,
        coalesce(solar_10, solar_30, solar_60)                         as solar,
        coalesce(sunshine_30, sunshine_60)                              as sunshine,
        coalesce(wind_direction_10, wind_direction_30, wind_direction_60) as wind_direction,
        coalesce(wind_speed_10, wind_speed_30, wind_speed_60)             as wind_speed,
        coalesce(wind_gust_direction_10, wind_gust_direction_30, wind_gust_direction_60) as wind_gust_direction,
        coalesce(wind_gust_speed_10, wind_gust_speed_30, wind_gust_speed_60)             as wind_gust_speed

    from {{ ref('stg_current_weather_observations') }}

),

latest_per_station as (

    select *
    from (
        select
            c.*,
            row_number() over (
                partition by c.source_id
                order by c."timestamp" desc, c.updated_at desc
            ) as rn
        from consolidated c
    ) sub
    where sub.rn = 1

),

final as (

    select
        source_id,
        "timestamp" as last_observation_at,
        cloud_cover,
        condition,
        dew_point,
        icon,
        pressure_msl,
        relative_humidity,
        temperature,
        visibility,
        fallback_source_ids,
        precipitation,
        solar,
        sunshine,
        wind_direction,
        wind_speed,
        wind_gust_direction,
        wind_gust_speed,

        -- freshness
        extract(epoch from (now() - "timestamp")) / 60.0 as minutes_since_last_observation

    from latest_per_station

)

select *
from final