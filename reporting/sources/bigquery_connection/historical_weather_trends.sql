select trend_id, reading_date, location_latitude, location_longitude, avg_temperature, max_temperature, min_temperature, avg_precipitation_chance, mart_updated_at
from project.dataset.table
where reading_date < date_sub(current_date(), interval 3 month)
order by reading_date asc
limit 100;