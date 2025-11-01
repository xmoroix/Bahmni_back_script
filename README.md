# Bahmni Backup & Restore Scripts

Comprehensive backup and restore solution for Bahmni Docker deployments.

## Features

- ✅ Full or selective backup/restore
- ✅ Interactive menu interface
- ✅ Timestamped backups with rotation
- ✅ Individual database restoration without affecting others
- ✅ Volume backup and restore
- ✅ Proper service isolation during restore
- ✅ Automatic compression (gzip)

## Installation

cd /path/to/bahmni-standard
git clone <your-repo-url> Bahmni_backup_script
chmod +x Bahmni_backup_script/*.sh

## Usage

### Interactive Menu

cd /path/to/bahmni-standard
./Bahmni_backup_script/bahmni_manager.sh

### Automated Cron Backup

Edit crontab
crontab -e

Add daily full backup at 2 AM
0 2 * * * cd /path/to/bahmni-standard && /path/to/bahmni-standard/Bahmni_backup_script/bahmni_backup_module.sh && bash -c 'source /path/to/bahmni-standard/Bahmni_backup_script/bahmni_backup_module.sh && full_backup' >> /path/to/bahmni-standard/bahmni-backups/cron.log 2>&1


## Directory Structure

bahmni-standard/
├── Bahmni_backup_script/
│ ├── bahmni_manager.sh # Main interactive menu
│ ├── bahmni_backup_module.sh # Backup functions
│ ├── bahmni_restore_module.sh # Restore functions
│ └── README.md # This file
├── bahmni-backups/
│ ├── backup_20251101_063000/
│ ├── backup_20251101_070000/
│ └── ...
├── docker-compose.yml
└── .env


## Backup Components

- **Databases**: OpenMRS, OpenELIS, Odoo, Reports, Metabase, Mart, PACS
- **Volumes**: Patient images, documents, forms, lab results, file storage
- **Configurations**: .env, docker-compose.yml, config directories

## Important Notes

- Restore operations stop all services first
- Each database is restored in isolation using `--no-deps` flag
- Database containers are stopped after restore before starting the next
- Full restore brings all services back up after completion
- Backups are kept with 5-copy rotation by default

## Troubleshooting

If restore fails:
1. Check Docker service is running
2. Verify backup files exist
3. Ensure sufficient disk space
4. Check service logs: `docker compose logs <service>`

## License

MIT

## Setup Instructions

# Navigate to bahmni-standard directory
cd /path/to/bahmni-standard

# Create the script directory
mkdir -p Bahmni_backup_script

# Create the three script files (paste content above)
# bahmni_manager.sh
# bahmni_backup_module.sh
# bahmni_restore_module.sh
# README.md

# Make scripts executable
chmod +x Bahmni_backup_script/*.sh

# Run the manager
./Bahmni_backup_script/bahmni_manager.sh
