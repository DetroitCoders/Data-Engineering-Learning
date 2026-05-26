{{
    config(
        materialized='incremental',
        unique_key='units_sk',
        incremental_strategy='merge'
    )
}}

with stage_data as (
  select *
  from {{ source('analytics', 'stg_openmeteo__forecast') }}
),

units_dim as (
  select
    distinct stage_data.hourly_units_time as hourly_units_time,
    stage_data.hourly_units_temperature_2m as hourly_units_temperature_2m,
    stage_data.hourly_units_precipitation_probability as hourly_units_precipitation_probability,
    stage_data.local_date as local_date,
    stage_data.fetch_time as fetch_time
  from stage_data
)

select
    {{ dbt_utils.generate_surrogate_key(['units_dim.hourly_units_time', 'units_dim.hourly_units_temperature_2m', 'units_dim.hourly_units_precipitation_probability']) }} as units_sk,
    units_dim.hourly_units_time as hourly_units_time,
    units_dim.hourly_units_temperature_2m as hourly_units_temperature_2m,
    units_dim.hourly_units_precipitation_probability as hourly_units_precipitation_probability
from units_dim

{% if is_incremental() %}
where units_dim.local_date >= (select max(units_dim.local_date) from {{ this }})
{% endif %}

qualify row_number() over (
  partition by units_sk 
  order by fetch_time desc
) = 1