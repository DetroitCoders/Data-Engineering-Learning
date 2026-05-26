{{
    config(
        materialized='incremental',
        unique_key='location_sk',
        incremental_strategy='merge'
    )
}}

with stage_data as (
  select *
  from {{ source('analytics', 'stg_openmeteo__forecast') }}
),

location_dim as (
    select distinct
        stage_data.latitude as latitude,
        stage_data.longitude as longitude,
        stage_data.elevation as elevation,
        stage_data.timezone as timezone,
        stage_data.timezone_abbreviation as timezone_abbreviation,
        stage_data.local_date as local_date,
        stage_data.fetch_time as fetch_time
    from stage_data
)
  select
    {{ dbt_utils.generate_surrogate_key(['location_dim.latitude', 'location_dim.longitude', 'location_dim.elevation', 'location_dim.timezone', 'location_dim.timezone_abbreviation']) }} as location_sk,
    location_dim.latitude as latitude,
    location_dim.longitude as longitude,
    location_dim.elevation as elevation,
    location_dim.timezone as timezone,
    location_dim.timezone_abbreviation as timezone_abbreviation
  from location_dim
        
  {% if is_incremental() %}
  where location_dim.local_date >= (select max(location_dim.local_date) from {{ this }})
  {% endif %}

  qualify row_number() over (
    partition by location_sk 
    order by fetch_time desc
  ) = 1