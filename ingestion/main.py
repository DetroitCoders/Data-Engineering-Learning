import os
import requests
import datetime
from google.cloud import bigquery
import functions_framework

# Using the @functions_framework decorator is standard for newer GCP Functions
@functions_framework.http
def main(request):
    """HTTP Cloud Function."""
    
    # 1. Setup BigQuery Client
    # The client automatically finds credentials via the Service Account
    client = bigquery.Client()
    
    # Use environment variables so you don't have to change code between Dev/Prod
    project_id = os.getenv("GCP_PROJECT_ID")
    dataset_id = os.getenv("GCP_DATASET_ID")
    table_name = "forecast"
    table_id = f"{project_id}.{dataset_id}.{table_name}"

    # 2. Fetch data from Open-Meteo
    url = "https://api.open-meteo.com/v1/forecast"
    params = {
        "latitude": 42.3314,
        "longitude": -83.0457,
        "hourly": ["temperature_2m", "precipitation_probability"],
        "timezone": "America/New_York",
        "wind_speed_unit": "mph",
        "temperature_unit": "fahrenheit",
        "precipitation_unit": "inch",
        # Pro-tip: Use relative dates if this is a daily job
        "past_days": 1,
        "forecast_days": 1
    }
    
    try:
        response = requests.get(url, params=params, timeout=10)
        response.raise_for_status() # Automatically triggers the except block if 4xx/5xx
        data = response.json()
    except requests.exceptions.RequestException as e:
        return f"API Connection Error: {e}", 500

    # 3. Prepare the row
    # We store the 'raw' response in its own field. 
    # This is the "Extract" part of ELT.
    row_to_insert = [{
        "fetch_time": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "raw_json_response": str(data), # Ensure this column is JSON type in BQ
        "insertion_source": "open_meteo_api_v1_forcast"
    }]

    # 4. Load into BigQuery
    errors = client.insert_rows_json(table_id, row_to_insert)

    if not errors:
        return {"status": "success", "message": "Data ingested"}, 200
    else:
        return {"status": "error", "errors": errors}, 500
