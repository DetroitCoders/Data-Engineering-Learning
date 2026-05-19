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
        stage_data.timezone_abbreviation as timezone_abbreviation
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