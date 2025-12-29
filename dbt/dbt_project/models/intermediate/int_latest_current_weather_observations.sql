-- in this model i tried to use safe nulling technique with logic of consolidating metrics' 10,30 and 60 min windows

with consolidated as (

    select
        "timestamp",
        station_id,

        -- safe-nulled
        case when cloud_cover is null or cloud_cover between 0 and 100 then cloud_cover end as cloud_cover,
        nullif(trim(condition), '') as condition,
        case when dew_point is null or dew_point between -100 and 60 then dew_point end as dew_point,
        nullif(trim(icon), '')      as icon,
        case when pressure_msl is null or pressure_msl between 800 and 1100 then pressure_msl end as pressure_msl,
        case when relative_humidity is null or relative_humidity between 0 and 100 then relative_humidity end as relative_humidity,
        case when temperature is null or temperature between -80 and 60 then temperature end as temperature,
        case when visibility is null or visibility >= 0 then visibility end as visibility,

        fallback_source_ids,
        inserted_at,
        updated_at,

        -- coalesced measures with safe-nulling
        coalesce(
            case when precipitation_10 is null or precipitation_10 >= 0 then precipitation_10 end,
            case when precipitation_30 is null or precipitation_30 >= 0 then precipitation_30 end,
            case when precipitation_60 is null or precipitation_60 >= 0 then precipitation_60 end
        ) as precipitation,

        coalesce(
            case when solar_10 is null or solar_10 >= 0 then solar_10 end,
            case when solar_30 is null or solar_30 >= 0 then solar_30 end,
            case when solar_60 is null or solar_60 >= 0 then solar_60 end
        ) as solar,

        coalesce(
            case when sunshine_30 is null or sunshine_30 >= 0 then sunshine_30 end,
            case when sunshine_60 is null or sunshine_60 >= 0 then sunshine_60 end
        ) as sunshine,

        coalesce(
            case when wind_direction_10 is null or wind_direction_10 between 0 and 360 then wind_direction_10 end,
            case when wind_direction_30 is null or wind_direction_30 between 0 and 360 then wind_direction_30 end,
            case when wind_direction_60 is null or wind_direction_60 between 0 and 360 then wind_direction_60 end
        ) as wind_direction,

        coalesce(
            case when wind_speed_10 is null or wind_speed_10 >= 0 then wind_speed_10 end,
            case when wind_speed_30 is null or wind_speed_30 >= 0 then wind_speed_30 end,
            case when wind_speed_60 is null or wind_speed_60 >= 0 then wind_speed_60 end
        ) as wind_speed,

        coalesce(
            case when wind_gust_direction_10 is null or wind_gust_direction_10 between 0 and 360 then wind_gust_direction_10 end,
            case when wind_gust_direction_30 is null or wind_gust_direction_30 between 0 and 360 then wind_gust_direction_30 end,
            case when wind_gust_direction_60 is null or wind_gust_direction_60 between 0 and 360 then wind_gust_direction_60 end
        ) as wind_gust_direction,

        coalesce(
            case when wind_gust_speed_10 is null or wind_gust_speed_10 >= 0 then wind_gust_speed_10 end,
            case when wind_gust_speed_30 is null or wind_gust_speed_30 >= 0 then wind_gust_speed_30 end,
            case when wind_gust_speed_60 is null or wind_gust_speed_60 >= 0 then wind_gust_speed_60 end
        ) as wind_gust_speed,
        is_all_flag_valid

    from {{ ref('stg_current_weather_observations') }}

),

latest_per_station as (

    select *
    from (
        select
            c.*,
            row_number() over (
                partition by c.station_id
                order by c."timestamp" desc, c.updated_at desc
            ) as rn
        from consolidated c
    ) sub
    where sub.rn = 1

),

final as (

    select
        station_id,
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
        is_all_flag_valid,

        -- freshness
        extract(epoch from (now() - "timestamp")) / 60.0 as minutes_since_last_observation

    from latest_per_station

)

select *
from final