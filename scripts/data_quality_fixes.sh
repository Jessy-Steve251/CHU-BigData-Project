#!/bin/bash
# ============================================================
# CHU Big Data Project — Data Quality Fixes
# Run on Cloudera VM ONLY (never use PowerShell for UTF-8 fixes)
# ============================================================

# IMPORTANT: These fixes must be run on Linux (Cloudera VM)
# PowerShell corrupts UTF-8 encoding with French accents!

SOURCE_DIR="/mnt"

echo "=== Data Quality Fixes ==="

# Fix 1: dim_location — Map 174 country-code death records to Étranger
echo "Fix 1: Mapping 2-letter country codes to Étranger in dim_location..."
awk -F';' 'BEGIN{OFS=";"} {
    if (length($2) == 2 && $2 !~ /^[0-9]/) {
        $4 = "Étranger"
        $5 = $2
    }
    print
}' "${SOURCE_DIR}/dim_location.csv" > "${SOURCE_DIR}/dim_location_fixed.csv"
mv "${SOURCE_DIR}/dim_location_fixed.csv" "${SOURCE_DIR}/dim_location.csv"

# Fix 2: Verify accent encoding (Étranger should be UTF-8)
echo "Fix 2: Checking UTF-8 encoding for accented characters..."
if grep -q "Étranger" "${SOURCE_DIR}/dim_location.csv"; then
    echo "  ✓ Étranger encoded correctly"
else
    echo "  ✗ WARNING: Accent encoding issue detected"
    # Fix hex encoding if needed
    sed -i 's/\xc3\x83\xc2\x89tranger/Étranger/g' "${SOURCE_DIR}/dim_location.csv"
fi

# Fix 3: fact_deces — Fix quoted fields with semicolons inside
echo "Fix 3: Note — CSV quoting handled in Talend (Text Enclosure = double-quote)"
echo "  Set tFileInputDelimited Text Enclosure AND Escape char to: \""

# Fix 4: Verify no NULL/empty values in key columns
echo ""
echo "=== Verification: Checking for empty values ==="
for file in dim_patient dim_provider dim_diagnosis dim_time dim_location \
            fact_consultation fact_hospitalisation fact_deces fact_satisfaction; do
    empty=$(awk -F';' '{for(i=1;i<=NF;i++) if($i=="") count++} END{print count+0}' \
            "${SOURCE_DIR}/${file}.csv" 2>/dev/null)
    if [ "$empty" -eq 0 ] 2>/dev/null; then
        echo "  ✓ ${file}: No empty values"
    else
        echo "  ✗ ${file}: ${empty} empty values found"
    fi
done

echo ""
echo "=== Sentinel Values Used ==="
echo "  diagnosis_key = -1        → Unknown diagnosis"
echo "  total_satisfaction = -1   → Missing satisfaction score"
echo "  nb_respondents = 0        → No respondents"
echo "  facility_name = 'Independent Practitioner' → No facility"
echo "  diagnosis_label = 'Non specifie' → No label available"
echo "  classement = 'NC'         → Not classified"

echo ""
echo "Done! Re-upload fixed files to HDFS."
