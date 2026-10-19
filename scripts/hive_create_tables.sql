-- ============================================================
-- CHU Big Data Project — Hive Table Creation Scripts
-- Database: chu_dw
-- Engine: Hive on MapReduce (Cloudera Quickstart VM)
-- ============================================================

CREATE DATABASE IF NOT EXISTS chu_dw;
USE chu_dw;

-- ============================================================
-- EXTERNAL TABLES (9 tables)
-- ============================================================

-- Dimension: Patient
CREATE EXTERNAL TABLE IF NOT EXISTS dim_patient_ext (
    patient_key     STRING,
    gender          STRING,
    age             INT,
    age_group       STRING,
    blood_group     STRING,
    birth_date      STRING,
    patient_source_id STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\073'
STORED AS TEXTFILE
LOCATION '/user/chu/datalake/gold/dimensions/dim_patient/';

-- Dimension: Provider
CREATE EXTERNAL TABLE IF NOT EXISTS dim_provider_ext (
    provider_key      STRING,
    provider_name     STRING,
    profession        STRING,
    speciality        STRING,
    facility_name     STRING,
    facility_source_id STRING,
    provider_source_id STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\073'
STORED AS TEXTFILE
LOCATION '/user/chu/datalake/gold/dimensions/dim_provider/';

-- Dimension: Diagnosis
CREATE EXTERNAL TABLE IF NOT EXISTS dim_diagnosis_ext (
    diagnosis_key       STRING,
    diagnosis_label     STRING,
    diagnosis_source_code STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\073'
STORED AS TEXTFILE
LOCATION '/user/chu/datalake/gold/dimensions/dim_diagnosis/';

-- Dimension: Time
CREATE EXTERNAL TABLE IF NOT EXISTS dim_time_ext (
    time_key       STRING,
    full_date      STRING,
    year           INT,
    month          INT,
    quarter        INT,
    day_of_month   INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\073'
STORED AS TEXTFILE
LOCATION '/user/chu/datalake/gold/dimensions/dim_time/';

-- Dimension: Location
CREATE EXTERNAL TABLE IF NOT EXISTS dim_location_ext (
    location_key   STRING,
    department     STRING,
    city           STRING,
    region         STRING,
    country        STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\073'
STORED AS TEXTFILE
LOCATION '/user/chu/datalake/gold/dimensions/dim_location/';

-- Fact: Consultation
CREATE EXTERNAL TABLE IF NOT EXISTS fact_consultation_ext (
    consultation_id     STRING,
    patient_key         STRING,
    provider_key        STRING,
    diagnosis_key       STRING,
    time_key            STRING,
    nbre_consultation   INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\073'
STORED AS TEXTFILE
LOCATION '/user/chu/datalake/gold/facts/fact_consultation/';

-- Fact: Hospitalisation
CREATE EXTERNAL TABLE IF NOT EXISTS fact_hospitalisation_ext (
    hospitalisation_id  STRING,
    patient_key         STRING,
    diagnosis_key       STRING,
    time_key            STRING,
    location_key        STRING,
    nbre_hospitalisation INT,
    avg_stay_days       DOUBLE
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\073'
STORED AS TEXTFILE
LOCATION '/user/chu/datalake/gold/facts/fact_hospitalisation/';

-- Fact: Deces (Deaths)
CREATE EXTERNAL TABLE IF NOT EXISTS fact_deces_ext (
    death_id       STRING,
    location_key   STRING,
    time_key       STRING,
    sexe           STRING,
    nbre_deces     INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\073'
STORED AS TEXTFILE
LOCATION '/user/chu/datalake/gold/facts/fact_deces/';

-- Fact: Satisfaction
CREATE EXTERNAL TABLE IF NOT EXISTS fact_satisfaction_ext (
    satisfaction_id    STRING,
    location_key       STRING,
    time_key           STRING,
    total_satisfaction DOUBLE,
    nb_respondents     INT,
    classement         STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\073'
STORED AS TEXTFILE
LOCATION '/user/chu/datalake/gold/facts/fact_satisfaction/';

-- ============================================================
-- OPTIMIZED TABLES — Partitioned (3 tables)
-- ============================================================

SET hive.exec.dynamic.partition=true;
SET hive.exec.dynamic.partition.mode=nonstrict;

-- Partitioned: Patient by gender + age_group
CREATE TABLE IF NOT EXISTS dim_patient_part (
    patient_key     STRING,
    age             INT,
    blood_group     STRING,
    birth_date      STRING,
    patient_source_id STRING
)
PARTITIONED BY (gender STRING, age_group STRING)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\073'
STORED AS TEXTFILE;

INSERT OVERWRITE TABLE dim_patient_part PARTITION(gender, age_group)
SELECT patient_key, age, blood_group, birth_date, patient_source_id,
       gender, age_group
FROM dim_patient_ext;

-- Partitioned: Location by region
CREATE TABLE IF NOT EXISTS dim_location_part (
    location_key   STRING,
    department     STRING,
    city           STRING,
    country        STRING
)
PARTITIONED BY (region STRING)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\073'
STORED AS TEXTFILE;

INSERT OVERWRITE TABLE dim_location_part PARTITION(region)
SELECT location_key, department, city, country, region
FROM dim_location_ext;

-- Partitioned: Time by year
CREATE TABLE IF NOT EXISTS dim_time_part (
    time_key       STRING,
    full_date      STRING,
    month          INT,
    quarter        INT,
    day_of_month   INT
)
PARTITIONED BY (year INT)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\073'
STORED AS TEXTFILE;

INSERT OVERWRITE TABLE dim_time_part PARTITION(year)
SELECT time_key, full_date, month, quarter, day_of_month, year
FROM dim_time_ext;

-- ============================================================
-- OPTIMIZED TABLES — Bucketed (3 tables)
-- ============================================================

SET hive.enforce.bucketing=true;

-- Bucketed: Patient by patient_key
CREATE TABLE IF NOT EXISTS dim_patient_buck (
    patient_key     STRING,
    gender          STRING,
    age             INT,
    age_group       STRING,
    blood_group     STRING,
    birth_date      STRING,
    patient_source_id STRING
)
CLUSTERED BY (patient_key) INTO 4 BUCKETS
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\073'
STORED AS TEXTFILE;

INSERT OVERWRITE TABLE dim_patient_buck
SELECT * FROM dim_patient_ext;

-- Bucketed: Location by location_key
CREATE TABLE IF NOT EXISTS dim_location_buck (
    location_key   STRING,
    department     STRING,
    city           STRING,
    region         STRING,
    country        STRING
)
CLUSTERED BY (location_key) INTO 4 BUCKETS
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\073'
STORED AS TEXTFILE;

INSERT OVERWRITE TABLE dim_location_buck
SELECT * FROM dim_location_ext;

-- Bucketed: Time by time_key
CREATE TABLE IF NOT EXISTS dim_time_buck (
    time_key       STRING,
    full_date      STRING,
    year           INT,
    month          INT,
    quarter        INT,
    day_of_month   INT
)
CLUSTERED BY (time_key) INTO 4 BUCKETS
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\073'
STORED AS TEXTFILE;

INSERT OVERWRITE TABLE dim_time_buck
SELECT * FROM dim_time_ext;
