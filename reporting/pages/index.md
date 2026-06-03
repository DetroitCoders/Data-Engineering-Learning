---
title: Gold Historical Weather Trends
---

# 📊 Highs, Lows, and Average Precipitation Chance

```sql historical_weather_trends
select reading_date, min_temperature, max_temperature, avg_precipitation_chance
from bigquery_connection.historical_weather_trends
group by all
order by reading_date
```
<LineChart
    data={historical_weather_trends}
    title="Historical Weather Trends"
    x=reading_date
    xAxisTitle="Latest 3 Months of Data"
    y={['min_temperature','max_temperature']}
    yAxisTitle="Temperature in Fahrenheit"
    y2=avg_precipitation_chance
    y2SeriesType=bar
/>
