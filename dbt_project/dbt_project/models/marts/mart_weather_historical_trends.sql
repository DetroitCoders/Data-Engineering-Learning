{{
    config(
        materialized='incremental',
        unique_key='trend_id',
        incremental_strategy='merge',
        cluster_by=['reading_date']
    )
}}

with fact_readings as (
    select * from {{ ref('core_fact__weather_readings') }}
),

dim_locations as (
    select * from {{ ref('core_dim__location') }}
),

dim_dates as (
    select * from {{ ref('core_dim__date') }}
)

select
    -- 1. Create a unique ID for the merge engine by combining the location and date
    {{ dbt_utils.generate_surrogate_key(['f.location_sk', 'f.date_sk']) }} as trend_id,

    -- 2. Time and Location Dimensions (The "Axes" for your trend charts)
    d.date_actual as reading_date,
    l.latitude as location_latitude,
    l.longitude as location_longitude,
    
    -- 3. Core Metrics (The "Lines" on your trend charts)
    -- We use aggregations in case your fact table has multiple readings per day,
    -- ensuring a clean 1-row-per-day grain for your trend lines.
    avg(f.temperature_2m_actual) as avg_temperature,
    max(f.temperature_2m_actual) as max_temperature,
    min(f.temperature_2m_actual) as min_temperature,
    avg(f.precipitation_probability_actual) as avg_precipitation_chance,
    
    -- 4. Audit column
    current_timestamp() as mart_updated_at

from fact_readings f
left join dim_locations l on f.location_sk = l.location_sk
left join dim_dates d on f.date_sk = d.date_sk

{% if is_incremental() %}
  -- Look back 3 days into the fact table to catch any late-arriving data 
  -- and seamlessly merge it into our historical trend timeline
  where d.date_actual >= DATE_SUB(CURRENT_DATE(), INTERVAL 3 DAY)
{% endif %}

group by 
    f.location_sk,
    f.date_sk,
    d.date_actual,
    l.latitude,
    l.longitude