#!/bin/bash

# Check for required environment variables
required_vars=(
    "FREESCOUT_DIR"
    "DB_HOST"
    "DB_PORT"
    "DB_USER"
    "DB_PASS"
    "DB_NAME"
    "R2_BUCKET"
    "R2_ACCESS_KEY_ID"
    "R2_SECRET_ACCESS_KEY"
    "R2_ENDPOINT"
    "TEMP_DIR"
)

for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "Error: Environment variable $var is not set."
        exit 1
    fi
done

# Function to download the latest backup from R2
download_latest_backup() {
    local file_type=$1
    local output_file=$2
    
    echo "Downloading latest $file_type backup..."
    latest_backup=$(AWS_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID" AWS_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY" aws s3 ls "s3://$R2_BUCKET/$file_type/" --endpoint-url "$R2_ENDPOINT" | sort -r | head -n 1 | awk '{print $4}')
    
    if [ -z "$latest_backup" ]; then
        echo "Error: No $file_type backup found in the R2 bucket."
        return 1
    fi
    
    echo "Latest $file_type backup: $latest_backup"
    AWS_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID" AWS_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY" aws s3 cp "s3://$R2_BUCKET/$file_type/$latest_backup" "$output_file" --endpoint-url "$R2_ENDPOINT"
}

# Restore files
echo "Restoring Freescout files..."
if download_latest_backup "files" "$TEMP_DIR/freescout_files_latest.tar.gz"; then
    tar -xzf "$TEMP_DIR/freescout_files_latest.tar.gz" -C "$FREESCOUT_DIR"
    echo "Files restored successfully!"
else
    echo "Failed to restore files."
    exit 1
fi

# Restore database
echo "Restoring Freescout database..."
if download_latest_backup "database" "$TEMP_DIR/database_latest.sql.gz"; then
    gunzip < "$TEMP_DIR/database_latest.sql.gz" | mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME"
    echo "Database restored successfully!"
else
    echo "Failed to restore database."
    exit 1
fi

# Clean up temp files
echo "Cleaning up..."
rm "$TEMP_DIR/freescout_files_latest.tar.gz" "$TEMP_DIR/database_latest.sql.gz"

echo "Restore completed successfully!"
