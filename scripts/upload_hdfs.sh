#!/bin/bash
# ============================================================
# CHU Big Data Project — HDFS Upload Script
# Run on Cloudera VM after mounting shared folder
# ============================================================

# Configuration
SOURCE_DIR="/mnt"                          # VirtualBox shared folder mount point
HDFS_BASE="/user/chu/datalake/gold"

# Step 1: Mount shared folder (if not already mounted)
echo "=== Step 1: Mounting shared folder ==="
sudo mount -t vboxsf chu_output /mnt 2>/dev/null || echo "Already mounted or manual mount needed"

# Step 2: Clean files (remove Windows line endings + headers)
echo ""
echo "=== Step 2: Cleaning CSV files ==="
TABLES="dim_patient dim_provider dim_diagnosis dim_time dim_location fact_consultation fact_hospitalisation fact_deces fact_satisfaction"

for table in $TABLES; do
    file="${SOURCE_DIR}/${table}.csv"
    if [ -f "$file" ]; then
        echo "Cleaning $table.csv..."
        sed -i 's/\r$//' "$file"      # Remove Windows \r\n → \n
        sed -i '1d' "$file"           # Remove header row
    else
        echo "WARNING: $file not found!"
    fi
done

# Step 3: Create HDFS directory structure
echo ""
echo "=== Step 3: Creating HDFS directories ==="
hdfs dfs -mkdir -p ${HDFS_BASE}/dimensions/dim_patient
hdfs dfs -mkdir -p ${HDFS_BASE}/dimensions/dim_provider
hdfs dfs -mkdir -p ${HDFS_BASE}/dimensions/dim_diagnosis
hdfs dfs -mkdir -p ${HDFS_BASE}/dimensions/dim_time
hdfs dfs -mkdir -p ${HDFS_BASE}/dimensions/dim_location
hdfs dfs -mkdir -p ${HDFS_BASE}/facts/fact_consultation
hdfs dfs -mkdir -p ${HDFS_BASE}/facts/fact_hospitalisation
hdfs dfs -mkdir -p ${HDFS_BASE}/facts/fact_deces
hdfs dfs -mkdir -p ${HDFS_BASE}/facts/fact_satisfaction

# Step 4: Upload files to HDFS
echo ""
echo "=== Step 4: Uploading to HDFS ==="
for table in $TABLES; do
    file="${SOURCE_DIR}/${table}.csv"
    if [ -f "$file" ]; then
        # Determine target directory
        if [[ "$table" == dim_* ]]; then
            target="${HDFS_BASE}/dimensions/${table}/"
        else
            target="${HDFS_BASE}/facts/${table}/"
        fi
        echo "Uploading $table.csv → $target"
        hdfs dfs -put -f "$file" "$target"
    fi
done

# Step 5: Verify uploads
echo ""
echo "=== Step 5: Verification ==="
echo "--- Dimensions ---"
for dim in dim_patient dim_provider dim_diagnosis dim_time dim_location; do
    echo -n "$dim: "
    hdfs dfs -ls ${HDFS_BASE}/dimensions/${dim}/ 2>/dev/null | grep -c ".csv"
    echo " file(s)"
done

echo "--- Facts ---"
for fact in fact_consultation fact_hospitalisation fact_deces fact_satisfaction; do
    echo -n "$fact: "
    hdfs dfs -ls ${HDFS_BASE}/facts/${fact}/ 2>/dev/null | grep -c ".csv"
    echo " file(s)"
done

echo ""
echo "=== Done! ==="
echo "Next: Run hive_create_tables.sql to create Hive tables"
