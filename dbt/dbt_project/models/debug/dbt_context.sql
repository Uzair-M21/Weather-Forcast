{{ config(materialized='table') }}

select
  current_database() as db,
  current_schema() as schema,
  current_user as user,
  current_setting('search_path') as search_path