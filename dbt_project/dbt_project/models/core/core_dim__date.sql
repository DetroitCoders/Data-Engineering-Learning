with stage_data as (
  select *
  from {{ source('analytics', 'stg_openmeteo__forecast') }}
),

date_dim as (
  select
    distinct date(stage_data.time_actual) as date_actual,
    date(stage_data.time_forecast) as date_forecast
  from stage_data
)

select
    {{ dbt_utils.generate_surrogate_key(['date_dim.date_actual', 'date_dim.date_forecast']) }} as date_sk,
    date_dim.date_actual as date_actual,
    date_dim.date_forecast as date_forecast,
    EXTRACT(year from date_dim.date_actual) as year_actual,
    EXTRACT(quarter from date_dim.date_actual) as quarter_actual,
    EXTRACT(month from date_dim.date_actual) as month_actual,
    EXTRACT(day from date_dim.date_actual) as day_actual,
    EXTRACT(week from date_dim.date_actual) as week_actual,
    EXTRACT(dayofweek from date_dim.date_actual) as dayofweek_actual,
    EXTRACT(dayofyear from date_dim.date_actual) as dayofyear_actual,
    CASE WHEN EXTRACT(dayofweek from date_dim.date_actual) IN (1, 5) THEN false ELSE true END as is_weekend_actual,    
    EXTRACT(year from date_dim.date_forecast) as year_forecast,
    EXTRACT(quarter from date_dim.date_forecast) as quarter_forecast,
    EXTRACT(month from date_dim.date_forecast) as month_forecast,
    EXTRACT(day from date_dim.date_forecast) as day_forecast,
    EXTRACT(week from date_dim.date_forecast) as week_forecast,
    EXTRACT(dayofweek from date_dim.date_forecast) as dayofweek_forecast,
    EXTRACT(dayofyear from date_dim.date_forecast) as dayofyear_forecast,
    CASE WHEN EXTRACT(dayofweek from date_dim.date_forecast) IN (1, 5) THEN false ELSE true END as is_weekend_forecast
from date_dim