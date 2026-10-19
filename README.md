# CHU Big Data — Healthcare Decision Support System

A Big Data decision support system for a Cloud Healthcare Unit (CHU), built as part of the Big Data Architecture course at **CESI École d'Ingénieurs, Lyon**.

## 📋 Project Overview

This project implements a complete data pipeline — from heterogeneous source ingestion through ETL, data lake storage, data warehousing, to interactive dashboards — answering **8 healthcare user needs** across consultations, hospitalizations, deaths, and patient satisfaction.

### Architecture (5 Layers)

```
Sources (PostgreSQL + CSV) → Talend ETL → HDFS Data Lake → Hive DW → Power BI
```

| Layer | Technology | Role |
|---|---|---|
| Sources | PostgreSQL 14 (Docker) + CSV flat files | Operational data |
| ETL | Talend Open Studio for Data Integration | Extract, transform, load (9 jobs) |
| Data Lake | HDFS on Hadoop (Cloudera Quickstart VM) | Distributed file storage |
| Data Warehouse | Apache Hive (MapReduce engine) | SQL analytics on Hadoop |
| Visualization | Microsoft Power BI | Dashboards & storytelling |

### Data Model — Constellation Schema

**5 Dimensions** + **4 Fact Tables** (constellation chosen over single star to avoid massive NULLs — death and satisfaction records lack patient/provider keys).

| Table | Type | Rows |
|---|---|---|
| dim_patient | Dimension | 100,000 |
| dim_provider | Dimension | 1,048,575 |
| dim_diagnosis | Dimension | 16,087 |
| dim_time | Dimension | 4,383 |
| dim_location | Dimension | 172,642 |
| fact_consultation | Fact | 1,027,157 |
| fact_hospitalisation | Fact | 2,479 |
| fact_deces | Fact | 620,608 |
| fact_satisfaction | Fact | 8,328 |

**Total:** ~700 MB raw → 328 MB after filtering (26.6M → 4.4M rows)

## 📊 Key Results

| User Need | Question | Key Finding |
|---|---|---|
| UN1 | Consultations by facility | SERVICE DE SANTE DES ARMEES: 812 (2016) |
| UN2 | Consultations by diagnosis | B170 hepatitis B: 34 (2018) |
| UN3 | Hospitalizations by year | 2017 peak: 458, avg ~15 days |
| UN4 | Hospitalizations by diagnosis | K010 Dents incluses: 3 |
| UN5 | Hospitalizations by gender/age | Female 65+: 19.1%, Male 65+: 14.7% |
| UN6 | Consultations per professional | MARTIN Michel: 70 |
| UN7 | Deaths by region (2019) | Île-de-France: 75,276 (12.1%) |
| UN8 | Satisfaction by region (2020) | Bretagne: 75.96% highest |

### Performance Optimization

| Query | Original | Partitioned | Bucketed | Improvement |
|---|---|---|---|---|
| UN3 | 127.0s | 124.3s | 114.7s | **9.7%** |
| UN5 | 155.8s | 188.5s | 113.3s | **27.3%** |
| UN7 | 194.0s | 154.5s | 122.6s | **36.8%** |

HDFS I/O reduction confirmed: UN5 −28%, UN7 −9.8%, UN3 −5.6%.

## 🗂 Repository Structure

```
CHU-BigData-Project/
├── README.md
├── .gitignore
├── docs/
│   └── data_quality_report.md      # 11 data quality issues & fixes
├── scripts/
│   ├── hive_create_tables.sql      # 15 Hive table DDL (9 external + 6 optimized)
│   ├── analysis_queries.sql        # 8 user need queries with results
│   ├── upload_hdfs.sh              # HDFS upload automation
│   └── data_quality_fixes.sh       # Linux-side data cleaning
├── data/
│   └── department_region_mapping.csv  # 101-row dept→region lookup
└── screenshots/
    └── power_bi_model.png          # Power BI constellation schema
```

> **Note:** Patient/provider/consultation CSV data files are excluded from this repository (`.gitignore`) as they contain anonymized but sensitive healthcare data.

## 🔧 Data Quality — 11 Issues Fixed

| Issue | Fix | Impact |
|---|---|---|
| Corsica (dept 20) unmapped | Added to mapping file | 7,354 deaths recovered |
| Foreign deaths (dept 99) | Added "Étranger" region | 5,594 deaths recovered |
| 174 country-code records | awk → set region to Étranger | 100% mapping achieved |
| Column misalignment | Defined all columns in Talend schema | Correct field parsing |
| Windows line endings | `sed -i 's/\r$//'` on VM | Hive parsing fixed |
| CSV quoted fields | Talend Text Enclosure = `"` | 4,371 date errors fixed |
| PowerShell UTF-8 corruption | Apply ALL text fixes on Linux VM only | Accent preservation |

**Result:** Zero NULL/empty values across all 9 tables. 620,607 of 620,608 death records mapped (99.9999%).

## ⚙️ Setup & Reproduction

### Prerequisites
- VirtualBox + Cloudera Quickstart VM (8 GB RAM)
- Docker (for PostgreSQL 14 source database)
- Talend Open Studio for Data Integration
- Microsoft Power BI Desktop
- Hive ODBC driver (for Power BI → Hive connection)

### Steps
1. Start PostgreSQL Docker container with source data
2. Run 9 Talend ETL jobs (output to `C:\chu_output\`)
3. Start Cloudera VM, mount shared folder: `sudo mount -t vboxsf chu_output /mnt`
4. Clean files: `scripts/data_quality_fixes.sh`
5. Upload to HDFS: `scripts/upload_hdfs.sh`
6. Create Hive tables: `hive -f scripts/hive_create_tables.sql`
7. Run analysis queries: `hive -f scripts/analysis_queries.sql`
8. Connect Power BI via ODBC to Hive

### Key Configuration
```bash
# Required Hive setting for large table joins
SET hive.auto.convert.join=false;

# Talend JVM for fact_consultation (1M+ rows)
-Xmx4096m
```

## 👥 Team

| Member | Role |
|---|---|
| BOMOU Mahamadou | Team member |
| FOFANA Mariama | Team member |
| STEPHEN Jessica | Team member |
| TCHOKOANSSI Emmanuel | Team member |

**Supervisor:** Dr. Raddad AL KING — CESI École d'Ingénieurs, Lyon, France

## 📝 Lessons Learned

1. **Always define ALL columns** in Talend `tFileInputDelimited` schema — column position errors are silent
2. **Never use PowerShell** to edit UTF-8 files with French accents — use Linux `sed`/`awk`
3. **Set Text Enclosure** to `"` for CSVs with quoted fields containing delimiters
4. **Use sentinel values** (`-1`, `"N/A"`, `"Non specifie"`) instead of NULLs in the data warehouse
5. **VM shared folder** mount is lost on restart — re-mount each time
6. **`hive.auto.convert.join=false`** is required for large table joins on Cloudera

## 📄 License

This project is part of academic coursework at CESI École d'Ingénieurs. The data is synthetic/anonymized and intended for educational purposes only.
