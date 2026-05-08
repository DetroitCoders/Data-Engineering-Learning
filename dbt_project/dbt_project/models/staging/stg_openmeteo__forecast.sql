with raw_data as (
  select *
  from {{ source('raw_openmeteo', 'forecast') }}
),

arrays as (
  select
    fetch_time,
    insertion_source,
    safe_cast(JSON_VALUE(raw_json_response, '$.latitude') as float64) as latitude,
    safe_cast(JSON_VALUE(raw_json_response, '$.longitude') as float64) as longitude,
    safe_cast(JSON_VALUE(raw_json_response, '$.generationtime_ms') as float64) as generationtime_ms,
    safe_cast(JSON_VALUE(raw_json_response, '$.utc_offset_seconds') as int64) as utc_offset_seconds,
    JSON_VALUE(raw_json_response, '$.timezone') as timezone,
    JSON_VALUE(raw_json_response, '$.timezone_abbreviation') as timezone_abbreviation,
    safe_cast(JSON_VALUE(raw_json_response, '$.elevation') as float64) as elevation,
    JSON_VALUE(raw_json_response, '$.hourly_units.time') as hourly_units_time,
    JSON_VALUE(raw_json_response, '$.hourly_units.temperature_2m') as hourly_units_temperature_2m,
    JSON_VALUE(raw_json_response, '$.hourly_units.precipitation_probability') as hourly_units_precipitation_probability,
    JSON_QUERY_ARRAY(raw_json_response, '$.hourly.time') as hourly_time_array,
    JSON_QUERY_ARRAY(raw_json_response, '$.hourly.temperature_2m') as hourly_temperature_array,
    JSON_QUERY_ARRAY(raw_json_response, '$.hourly.precipitation_probability') as hourly_precipitation_array
  from raw_data
),

actual_forecast as (
  select
    idx,
    fetch_time,
    insertion_source,
    latitude,
    longitude,
    generationtime_ms,
    utc_offset_seconds,
    timezone,
    timezone_abbreviation,
    elevation,
    hourly_units_time,
    hourly_units_temperature_2m,
    hourly_units_precipitation_probability,
    CONCAT(trim(hourly_time_array[offset(idx)], '"'), ':00') as time_actual,
    CONCAT(trim(hourly_time_array[offset(idx + 24)],'"'), ':00') as time_forecast,
    safe_cast(hourly_temperature_array[offset(idx)] as float64) as temperature_2m_actual,
    safe_cast(hourly_temperature_array[offset(idx + 24)] as float64) as temperature_2m_forecast,
    safe_cast(hourly_precipitation_array[offset(idx)] as int64) as precipitation_probability_actual,
    safe_cast(hourly_precipitation_array[offset(idx + 24)] as int64) as precipitation_probability_forecast
  from arrays,
  unnest(generate_array(0, 23)) as idx
)

select
  fetch_time,
  insertion_source,
  latitude,
  longitude,
  generationtime_ms,
  utc_offset_seconds,
  timezone,
  timezone_abbreviation,
  elevation,
  hourly_units_time,
  hourly_units_temperature_2m,
  hourly_units_precipitation_probability,
  TIMESTAMP(time_actual, timezone) as hourly_time,
  TIMESTAMP(time_actual, timezone) as time_actual,
  TIMESTAMP(time_forecast, timezone) as time_forecast,
  temperature_2m_actual,
  temperature_2m_forecast,
  precipitation_probability_actual,
  precipitation_probability_forecast
from actual_forecast
order by hourly_time