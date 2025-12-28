create schema if not exists raw;

create extension if not exists postgis with schema raw;

alter role dw set search_path = raw, pg_catalog;