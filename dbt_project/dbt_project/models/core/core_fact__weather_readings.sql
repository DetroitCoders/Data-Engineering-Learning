with stage_data as (
  select *
  from {{ source('analytics', 'stg_openmeteo__forecast') }}
),

dates as (
  select * from {{ ref('core_dim__date') }}
),

locations as (
  select * from {{ ref('core_dim__location') }}
),

units as (
  select * from {{ ref('core_dim__units') }}
),

weather_readings_core as (
    select
        {{ dbt_utils.generate_surrogate_key(['dates.date_sk', 'locations.location_sk', 'units.units_sk', 'stage_data.hourly_time']) }} as weather_reading_sk,
        dates.date_sk as date_sk,
        locations.location_sk as location_sk,
        units.units_sk as units_sk,
        stage_data.hourly_time as hourly_time,
        stage_data.temperature_2m_actual as temperature_2m_actual,
        stage_data.temperature_2m_forecast as temperature_2m_forecast,
        stage_data.precipitation_probability_actual as precipitation_probability_actual,
        stage_data.precipitation_probability_forecast as precipitation_probability_forecast
    from stage_data
    left join dates 
        on DATE(stage_data.time_actual) = dates.date_actual
        and DATE(stage_data.time_forecast) = dates.date_forecast
    left join locations
        on stage_data.latitude = locations.latitude
        and stage_data.longitude = locations.longitude
        and stage_data.elevation = locations.elevation
        and stage_data.timezone = locations.timezone
        and stage_data.timezone_abbreviation = locations.timezone_abbreviation
    left join units
        on stage_data.hourly_units_time = units.hourly_units_time
        and stage_data.hourly_units_temperature_2m = units.hourly_units_temperature_2m
        and stage_data.hourly_units_precipitation_probability = units.hourly_units_precipitation_probability
)

select * from weather_readings_core