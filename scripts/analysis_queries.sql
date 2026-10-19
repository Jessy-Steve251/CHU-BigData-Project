-- ============================================================
-- CHU Big Data Project — Analysis Queries (8 User Needs)
-- Database: chu_dw | Engine: Hive on MapReduce
-- ============================================================

USE chu_dw;
SET hive.auto.convert.join=false;

-- ============================================================
-- UN1: Patient consultation rate by facility over time
-- Result: SERVICE DE SANTE DES ARMEES leads (812, 2016)
-- Execution: 254.6s, 4 MR jobs, 185.1 MB HDFS read
-- ============================================================
SELECT p.facility_name, t.year, COUNT(*) AS total_consultations
FROM fact_consultation_ext f
JOIN dim_provider_ext p ON f.provider_key = p.provider_key
JOIN dim_time_ext t ON f.time_key = t.time_key
GROUP BY p.facility_name, t.year
ORDER BY total_consultations DESC
LIMIT 20;

-- ============================================================
-- UN2: Patient consultation rate by diagnosis over time
-- Result: B170 hepatitis B (34 consultations, 2018)
-- Execution: 298.5s, 4 MR jobs, 153.2 MB HDFS read
-- ============================================================
SELECT d.diagnosis_key, d.diagnosis_label, t.year,
       COUNT(*) AS total_consultations
FROM fact_consultation_ext f
JOIN dim_diagnosis_ext d ON f.diagnosis_key = d.diagnosis_key
JOIN dim_time_ext t ON f.time_key = t.time_key
WHERE d.diagnosis_key != '-1'
GROUP BY d.diagnosis_key, d.diagnosis_label, t.year
ORDER BY total_consultations DESC
LIMIT 10;

-- ============================================================
-- UN3: Overall hospitalization rate by year
-- Result: 2017 peak (458), avg ~15 days stay
-- Execution: 188.9s, 3 MR jobs
-- ============================================================
SELECT t.year,
       COUNT(*) AS total_hospitalisations,
       AVG(f.avg_stay_days) AS avg_duration_days
FROM fact_hospitalisation_ext f
JOIN dim_time_ext t ON f.time_key = t.time_key
GROUP BY t.year
ORDER BY t.year;

-- ============================================================
-- UN4: Hospitalization rate by diagnosis
-- Result: K010 Dents incluses (3 hospitalizations)
-- Execution: 117.8s, 3 MR jobs
-- ============================================================
SELECT d.diagnosis_key, d.diagnosis_label,
       COUNT(*) AS total_hospitalisations
FROM fact_hospitalisation_ext f
JOIN dim_diagnosis_ext d ON f.diagnosis_key = d.diagnosis_key
WHERE d.diagnosis_key != '-1'
GROUP BY d.diagnosis_key, d.diagnosis_label
ORDER BY total_hospitalisations DESC
LIMIT 20;

-- ============================================================
-- UN5: Hospitalization rate by gender and age group
-- Result: Female 65+: 473 (19.1%), Male 65+: 365 (14.7%)
-- Execution: 108.9s, 3 MR jobs
-- ============================================================
SELECT p.gender, p.age_group,
       COUNT(*) AS total_hospitalisations
FROM fact_hospitalisation_ext f
JOIN dim_patient_ext p ON f.patient_key = p.patient_key
GROUP BY p.gender, p.age_group
ORDER BY p.gender, p.age_group;

-- ============================================================
-- UN6: Consultation rate per professional
-- Result: MARTIN Michel (70 consultations)
-- Execution: 172.2s, 3 MR jobs
-- ============================================================
SELECT p.provider_name, p.speciality,
       COUNT(*) AS total_consultations
FROM fact_consultation_ext f
JOIN dim_provider_ext p ON f.provider_key = p.provider_key
GROUP BY p.provider_name, p.speciality
ORDER BY total_consultations DESC
LIMIT 20;

-- ============================================================
-- UN7: Number of deaths by region in 2019
-- Result: IDF 75,276 | Total 620,607 | 100% mapped
-- Execution: 187.4s, 3 MR jobs
-- ============================================================
SELECT l.region, COUNT(*) AS total_deaths
FROM fact_deces_ext f
JOIN dim_location_ext l ON f.location_key = l.location_key
GROUP BY l.region
ORDER BY total_deaths DESC;

-- ============================================================
-- UN8: Overall satisfaction rate by region for 2020
-- Result: Bretagne 75.96% highest, Guyane 66.74% lowest
-- Execution: 101.2s, 2 MR jobs (no join needed)
-- ============================================================
SELECT region,
       AVG(total_satisfaction) AS avg_satisfaction,
       COUNT(*) AS facilities_surveyed
FROM (
    SELECT l.region, f.total_satisfaction
    FROM fact_satisfaction_ext f
    JOIN dim_location_ext l ON f.location_key = l.location_key
    WHERE f.time_key LIKE '2020%'
    AND f.total_satisfaction != -1
) sub
GROUP BY region
ORDER BY avg_satisfaction DESC;
