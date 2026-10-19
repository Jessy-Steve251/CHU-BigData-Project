# Data Quality Report — CHU Big Data Project

## Summary

11 data quality issues were identified and resolved during the ETL phase. After fixes, **zero NULL/empty values** exist across all 9 dimension and fact tables.

## Issues & Fixes

### 1. Corsica Department Missing from Mapping
- **Problem:** Department code "20" (Corse) was not in `department_region_mapping.csv`
- **Fix:** Added row `20;Corse;Corse` to mapping file
- **Impact:** 7,354 death records correctly mapped to Corse region

### 2. Foreign Deaths Showing as Unknown
- **Problem:** Department code "99" (foreign deaths) unmapped → showed as "Unknown"
- **Fix:** Added row `99;Étranger;Étranger` to mapping file
- **Impact:** 5,594 death records correctly mapped

### 3. Country-Code Death Records (174 rows)
- **Problem:** 174 records in `deces_2019` had 2-letter ISO country codes instead of department numbers
- **Fix:** `awk` script: if department field is 2 alphabetic characters → set region to "Étranger"
- **Impact:** 100% of death records now mapped (620,607 of 620,608)

### 4. dim_location Column Misalignment
- **Problem:** Talend `tFileInputDelimited` for deces source had only 5 of 11 columns defined → field positions shifted
- **Fix:** Defined all 11 columns in the Talend schema
- **Impact:** `nom` (name) field was being read as `code` → correct parsing restored

### 5. dim_diagnosis Column Misalignment
- **Problem:** Hospitalization source had 7 columns but only 3 were defined in Talend
- **Fix:** Defined all 7 columns; used `StringHandling.LEFT(row.code, 4)` to truncate to 4-char ICD codes
- **Impact:** Correct diagnosis code extraction

### 6. Provider ID Padding Inconsistency
- **Problem:** Some provider IDs were 8 digits (needing zero-padding to 9), others were already 9
- **Fix:** Conditional padding: `row.id.length() == 8 ? "0" + row.id : row.id`
- **Impact:** Correct provider key matching across fact and dimension tables

### 7. Windows Line Endings
- **Problem:** Files created on Windows had `\r\n` line endings → Hive parsing errors
- **Fix:** `sed -i 's/\r$//'` on every CSV before HDFS upload
- **Impact:** All Hive tables load correctly

### 8. CSV Headers in Hive
- **Problem:** `skip.header.line.count` property failed for `fact_consultation` (large file)
- **Fix:** `sed -i '1d'` to remove header row directly from all files
- **Impact:** No header rows appear as data in Hive tables

### 9. Quoted Fields in fact_deces CSV
- **Problem:** 4,371 death records had names containing semicolons inside double quotes → field splitting errors
- **Fix:** Set Talend `tFileInputDelimited` Text Enclosure AND Escape character to `"`
- **Impact:** `time_key` no longer shows NULL for these records

### 10. PowerShell UTF-8 Corruption
- **Problem:** Applying `sed`-equivalent fixes in PowerShell on `dim_location.csv` and `dim_provider.csv` corrupted UTF-8 accented characters (É → garbled bytes)
- **Fix:** Re-ran all text fixes on the Cloudera VM using Linux `sed`/`awk` instead
- **Lesson:** **Never use PowerShell for UTF-8 text operations on files with French accents**

### 11. NULL/Empty Value Handling (Sentinel Values)
- **Problem:** Various NULL/empty values across dimension and fact tables
- **Fix:** Talend jobs replace NULLs with sentinel values:

| Field | Sentinel Value | Meaning |
|---|---|---|
| `diagnosis_key` | `-1` | Unknown diagnosis |
| `diagnosis_label` | `Non specifie` | No label available |
| `total_satisfaction` | `-1` | Missing score |
| `nb_respondents` | `0` | No respondents |
| `facility_name` | `Independent Practitioner` | No facility |
| `speciality` | `Non specifie` | No specialty |
| `classement` | `NC` | Not classified |
| `time_key` | `00000000` | Missing date |

## Verification

Final data integrity check (Hive queries returning 0 for all):
```sql
-- Example: Check for empty values in dim_patient
SELECT COUNT(*) FROM dim_patient_ext
WHERE patient_key IS NULL OR patient_key = ''
   OR gender IS NULL OR gender = ''
   OR age_group IS NULL OR age_group = '';
-- Result: 0
```

**All 9 tables verified: zero NULL/empty values.**
