{{ config(
    materialized='incremental',
    incremental_strategy='delete+insert',
    unique_key=['station_id', 'forecast_ts', 'valid_from']
) }}

with watermark as (
    {% if is_incremental() %}
    select max(valid_from) as max_valid_from --we would have to change this logic if stations data arrive at different time, currently all arrives at the same time

    from {{ this }}
    {% else %}
    select '1900-01-01'::timestamptz as max_valid_from
    {% endif %}
),

incoming_raw as (
    -- Step 0: only new snapshots since last run
    select
        station_id,
        forecast_ts,

        precipitation,
        pressure_msl,
        sunshine,
        temperature,
        wind_direction,
        wind_speed,
        cloud_cover,
        dew_point,
        relative_humidity,
        visibility,
        wind_gust_direction,
        wind_gust_speed,
        condition,
        precipitation_probability,
        precipitation_probability_6h,
        solar,
        fallback_source_ids,
        icon,

        inserted_at as valid_from

    from {{ ref('stg_forecast_weather') }}
    where inserted_at > (select max_valid_from from watermark)
),

incoming as (
    -- Step 1: hash columns to check changes"
    select
        *,
        --I am keeping only relevant clumns
        md5(concat_ws('||',
            coalesce(temperature::text,''),
            coalesce(precipitation::text,''),
            coalesce(wind_speed::text,''),
            coalesce(wind_direction::text,''),
            coalesce(cloud_cover::text,''),
            coalesce(condition,''),
            coalesce(icon,'')
        )) as record_hash
    from incoming_raw
),

incoming_dedup as (
    -- Optional: protect against duplicates with same PK+valid_from in staging
    select *
    from (
        select
            *,
            row_number() over (
                partition by station_id, forecast_ts, valid_from
                order by valid_from
            ) as rn
        from incoming
    ) sub
    where rn = 1
),

current_open as (
    -- Step 2: current open records in the SCD table (state)
    {% if is_incremental() %}
    select
        station_id,
        forecast_ts,

        precipitation,
        pressure_msl,
        sunshine,
        temperature,
        wind_direction,
        wind_speed,
        cloud_cover,
        dew_point,
        relative_humidity,
        visibility,
        wind_gust_direction,
        wind_gust_speed,
        condition,
        precipitation_probability,
        precipitation_probability_6h,
        solar,
        fallback_source_ids,
        icon,

        record_hash,
        valid_from,
        valid_to,
        is_current
    from {{ this }}
    where valid_to is null
    {% else %}
    select
        null::text as station_id,
        null::timestamptz as forecast_ts,

        null::numeric as precipitation,
        null::numeric as pressure_msl,
        null::numeric as sunshine,
        null::numeric as temperature,
        null::integer as wind_direction,
        null::numeric as wind_speed,
        null::integer as cloud_cover,
        null::numeric as dew_point,
        null::integer as relative_humidity,
        null::integer as visibility,
        null::integer as wind_gust_direction,
        null::numeric as wind_gust_speed,
        null::text as condition,
        null::numeric as precipitation_probability,
        null::numeric as precipitation_probability_6h,
        null::numeric as solar,
        null::jsonb as fallback_source_ids,
        null::text as icon,

        null::text as record_hash,
        null::timestamptz as valid_from,
        null::timestamptz as valid_to,
        null::boolean as is_current
    where false
    {% endif %}
),

-- Step 3: decide which incoming rows are new versions (new entity OR hash differs from current open)
incoming_marked as (
    select
        i.*,
        c.record_hash as current_hash,
        c.valid_from   as current_valid_from
    from incoming_dedup i
    left join current_open c
      on i.station_id = c.station_id
     and i.forecast_ts = c.forecast_ts
),

kept as (
    select *
    from incoming_marked
    where current_hash is null
       or current_hash is distinct from record_hash
),

-- Step 4: if multiple kept rows for the same PK arrive in this run, keep changes within-batch too
kept_dedup_changes as (
    select *
    from (
        select
            *,
            lag(record_hash) over (
                partition by station_id, forecast_ts
                order by valid_from
            ) as prev_batch_hash
        from kept
    ) sub
    where prev_batch_hash is distinct from record_hash
),

-- Step 4 continued: compute valid_to windows among the kept rows
new_versions as (
    select
        station_id,
        forecast_ts,

        precipitation,
        pressure_msl,
        sunshine,
        temperature,
        wind_direction,
        wind_speed,
        cloud_cover,
        dew_point,
        relative_humidity,
        visibility,
        wind_gust_direction,
        wind_gust_speed,
        condition,
        precipitation_probability,
        precipitation_probability_6h,
        solar,
        fallback_source_ids,
        icon,

        record_hash,
        valid_from,

        lead(valid_from) over (
            partition by station_id, forecast_ts
            order by valid_from
        ) as valid_to

    from kept_dedup_changes
),

new_rows as (
    select
        *,
        (valid_to is null) as is_current
    from new_versions
),

-- Step 5: close previous open record at the FIRST new version time
first_new as (
    select
        station_id,
        forecast_ts,
        min(valid_from) as first_new_valid_from
    from new_rows
    group by 1,2
),

close_rows as (
    select
        c.station_id,
        c.forecast_ts,

        c.precipitation,
        c.pressure_msl,
        c.sunshine,
        c.temperature,
        c.wind_direction,
        c.wind_speed,
        c.cloud_cover,
        c.dew_point,
        c.relative_humidity,
        c.visibility,
        c.wind_gust_direction,
        c.wind_gust_speed,
        c.condition,
        c.precipitation_probability,
        c.precipitation_probability_6h,
        c.solar,
        c.fallback_source_ids,
        c.icon,

        c.record_hash,
        c.valid_from,
        f.first_new_valid_from as valid_to,
        false as is_current
    from current_open c
    join first_new f
      on f.station_id = c.station_id
     and f.forecast_ts = c.forecast_ts
)

-- Final:  "closed old rows" (to update) + "new versions" (to insert)
select * from close_rows
union all
select * from new_rows