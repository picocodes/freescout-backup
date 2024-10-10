# Freescout Backup and Restore Scripts

This repository contains scripts for backing up and restoring a Freescout installation, including both files and database. The scripts use Cloudflare R2 for storage and are designed to be run as cron jobs or manually as needed.

## Prerequisites

- Bash
- MySQL client
- AWS CLI
- `pv` (Pipe Viewer)
- Access to a Freescout installation
- AWS S3 or Cloudflare R2 bucket

## Mark both scripts as executable

```bash
chmod +x restore-backup.sh
chmod +x backup.sh
```

## Environment Variables

Both scripts require the following environment variables to be set:

- `FREESCOUT_DIR`: Directory of your Freescout installation
- `DB_HOST`: MySQL database host
- `DB_PORT`: MySQL database port
- `DB_USER`: MySQL database user
- `DB_PASS`: MySQL database password
- `DB_NAME`: MySQL database name
- `R2_BUCKET`: Name of your Cloudflare R2 bucket
- `R2_ACCESS_KEY_ID`: Cloudflare R2 access key ID
- `R2_SECRET_ACCESS_KEY`: Cloudflare R2 secret access key
- `R2_ENDPOINT`: Cloudflare R2 endpoint URL
- `TEMP_DIR`: Temporary directory for storing backups

## Backup Script (`backup.sh`)

This script creates backups of both the Freescout files and database, then uploads them to Cloudflare R2.

### Features

- Creates compressed backups of Freescout files and database
- Uploads backups to Cloudflare R2
- Manages retention by keeping only the 5 most recent backups
- Uses `pv` to show progress during backup creation and upload

### Usage

1. Set the required environment variables
2. Run the script:

```bash
./backup.sh
```

## Restore Script (`restore.sh`)

This script restores the latest backups of both Freescout files and database from Cloudflare R2.

### Features

- Downloads the latest file and database backups from Cloudflare R2
- Restores files to the Freescout directory
- Imports the database backup into MySQL

### Usage

1. Set the required environment variables
2. Run the script:

```bash
./restore-backup.sh
```

## Setting Up as a Cron Job

To run the backup script automatically, you can set up a cron job. For example, to run the backup daily at 2 AM:

1. Open the crontab file:

```bash
crontab -e
```

2. Add the following line (adjust the path as needed):
```bash
0 2 /path/to/backup.sh > /path/to/backup.log 2>&1
```


## Security Considerations

- Keep your environment variables secure and don't expose them in public repositories
- Ensure that only authorized users have access to these scripts and the backup storage
- Regularly test your backups by performing test restores

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
