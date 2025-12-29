    {{ config(materialized='view') }}
    select
        * --currently i do not have any changes on the staging layer for this table
    from raw.current_weather_observations