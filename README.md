# Data-Engineering-Learning
This is a monrepo for practicing data engineering concepts on GCP and dbt for transformations.

## Project Overview
This project demonstrates an **End-to-End ELT Pipeline** designed to provide business insights into weather patterns. As a consultant-level project, it focuses on scalability, automation, and a "Single Source of Truth" using a **monorepo structure**.

### The Business Goal (Insights)
**Daily Risk Assessment:** Correlate temperature and wind speed to identify operational risks.
**Historical Trends:** Track 7-day moving averages for temperature to predict demand spikes.

---

## Architecture Blueprint
This project follows a layered architecture entirely within **Google Cloud Platform**, offloading processing power to the cloud to accommodate development on older hardware.


1.  **Extraction:** Python script (stateless logic) deployed via **Google Cloud Functions**.
2.  **Automation:** **GitHub Actions** handles CI/CD, secret management, and deployment.
3.  **Data Warehouse (BigQuery):**
    * **RAW Layer:** Landed JSON data directly from the Open-Meteo API.
    * **STAGING Layer:** Views that clean, cast data types, and rename columns.
    * **CORE Layer:** Fact and Dimension tables (Star Schema) built with **dbt-core** on **Cloud Run**.
    * **MART Layer:** Flattened tables optimized for high-performance dashboarding.
4.  **Visualization:** **Looker Studio** for the final professional reporting layer.

---

## Data Flow & Logic

### 1. Extraction (The Source)
* **API:** Open-Meteo (No-key weather data).
* **Ingestion Tool:** Serverless Python 3.x Cloud Function triggered by Cloud Scheduler.
* **Target:** `project-id.raw_weather.daily_stats` using `insert_rows_json` for efficient streaming.
* **Security:** Authenticated via Service Account with `BigQuery Data Editor` permissions.

### 2. Transformation (The ELT)
Using **dbt-core** containerized in **Artifact Registry** to manage the logic:

* **Staging:** Handle nulls and create business-friendly aliases for API fields.
* **Core (Star Schema):**
    * `dim_location`: Metadata for coordinates.
    * `dim_date`: Date dimension for time-series analysis.
    * `fact_weather_readings`: Granular metrics including temperature and wind speed.
* **Marts:** `mart_weather_summary` for executive-level KPIs.

---

## Deployment & Infrastructure
* **Identity & Access:** Managed via a dedicated **GCP Service Account**.
* **Infrastructure as Code:** GCP resources automated via GitHub Actions to ensure zero local footprint.
* **Orchestration:** **Cloud Scheduler** triggers both the ingestion (Cloud Function) and transformation (Cloud Run) daily.
* **Cost Management:** Utilizes GCP's "Always Free" tier and serverless "pay-as-you-go" compute to keep costs near $0.

---

## Repository Structure
```text
/
├── .github/workflows/      # CI/CD workflows
├── ingestion/              # Python extraction logic
│   ├── main.py
│   └── requirements.txt
├── dbt_project/            # dbt transformation logic
│   ├── models/
│   │   ├── staging/
│   │   ├── core/
│   │   └── marts/
│   ├── Dockerfile          # Container instructions for Cloud Run
│   ├── .dockerignore       
│   ├── dbt_project.yml
│   └── profiles.yml        # Configured to use Service Account Auth
├── keys/                   # LOCAL ONLY: Service Account JSON (GITIGNORED)
├── .gitignore              # Explicitly ignores /keys folder and .env
└── README.md               # Project documentation