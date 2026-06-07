select trend_id, reading_date, location_latitude, location_longitude, avg_temperature, max_temperature, min_temperature, avg_precipitation_chance, mart_updated_at
from analytics.mart_weather_historical_trends
where reading_date between date_sub(current_date(), interval 90 day) and current_date()
order by reading_date asc
limit 100;