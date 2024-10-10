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

echo "Great! Your temporary directory is available:" $TEMP_DIR

# Get current date and time
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

# Backup Freescout files
echo "Backing up Freescout files..."
if cd "$FREESCOUT_DIR"; then
    tar -cf - . | pv -s $(du -sb . | awk '{print $1}') | gzip > "$TEMP_DIR/freescout_files_$TIMESTAMP.tar.gz"
    echo "Files fully backed up!"
else
    echo "ERROR: Failed to change directory to Freescout directory" >&2
    exit 1
fi

# Backup MySQL database
echo "Backing up Freescout MySQL database..."
if mysqldump --quick --compress -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" | pv -p -t -e -s "$(mysqldump -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" | wc -c)" | gzip > "$TEMP_DIR/database_$TIMESTAMP.sql.gz"; then
    echo "MySQL Backup Successful."
else
    echo "ERROR: MySQL backup failed" >&2
    exit 1
fi

# Function to upload file to R2 and manage retention
upload_to_r2() {
    local file=$1
    local file_type=$2
    
    echo "Uploading $file_type to Cloudflare R2..."
    if AWS_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID" AWS_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY" aws s3 cp "$file" "s3://$R2_BUCKET/$file_type/" --endpoint-url "$R2_ENDPOINT"; then
        echo "Upload Successful!"
        
        # List files, sort by date, and keep only the newest 5
        echo "Managing retention for $file_type backups..."
        old_backups=$(AWS_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID" AWS_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY" aws s3 ls "s3://$R2_BUCKET/$file_type/" --endpoint-url "$R2_ENDPOINT" | sort -r | tail -n +6 | awk '{print $4}')
        
        for old_backup in $old_backups; do
            echo "Removing old backup: $old_backup"
            AWS_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID" AWS_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY" aws s3 rm "s3://$R2_BUCKET/$file_type/$old_backup" --endpoint-url "$R2_ENDPOINT"
        done
    else
        echo "ERROR: Upload of $file_type failed" >&2
        exit 1
    fi
}

# Upload files backup
upload_to_r2 "$TEMP_DIR/freescout_files_$TIMESTAMP.tar.gz" "files"

# Upload database backup
upload_to_r2 "$TEMP_DIR/database_$TIMESTAMP.sql.gz" "database"

# Clean up temp files
echo "Cleaning Up For The Next Run!"
rm "$TEMP_DIR/freescout_files_$TIMESTAMP.tar.gz" "$TEMP_DIR/database_$TIMESTAMP.sql.gz"
echo "Backup Completed Successfully!"
