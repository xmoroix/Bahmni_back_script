# Bahmni Backup & Restore Scripts

Comprehensive backup and restore solution for Bahmni Docker deployments.

---

## Table of contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
  - [Interactive menu](#interactive-menu)
  - [Automated (cron) backups](#automated-cron-backups)
- [Directory structure](#directory-structure)
- [What is backed up](#what-is-backed-up)
- [Restore behavior and notes](#restore-behavior-and-notes)
- [Troubleshooting](#troubleshooting)
- [License](#license)

---

## Features

- ✅ Full or selective backup and restore
- ✅ Interactive menu-based manager
- ✅ Timestamped backups with rotation (default: 5 copies)
- ✅ Individual database restoration (isolated, without affecting others)
- ✅ Volume backup and restore (files, images, attachments)
- ✅ Proper service isolation during restore (stops services before restoring)
- ✅ Automatic compression using gzip

---

## Requirements

- Docker and Docker Compose installed and available in PATH
- A running Bahmni deployment based on the `bahmni-standard` layout (or equivalent compose setup)
- Sufficient disk space for backups
- Bash (scripts are written for Bash)

---

## Installation

From your `bahmni-standard` directory:

1. Clone the repository (replace `<your-repo-url>` if you forked or mirrored it):

   ```bash
   git clone https://github.com/xmoroix/Bahmni_back_script.git Bahmni_backup_script
   ```

2. Make the scripts executable:

   ```bash
   chmod +x Bahmni_backup_script/*.sh
   ```

3. Run the interactive manager (see Usage below).

---

## Usage

All commands below assume you are in the `bahmni-standard` root directory.

### Interactive menu

Run the manager script to see an interactive menu with options to backup, restore, list backups, and configure rotation:

```bash
./Bahmni_backup_script/bahmni_manager.sh
```

Follow the prompts to perform full or selective backups and restores.

### Automated (cron) backups

To run a daily full backup at 02:00 AM, add a crontab entry for a user with access to Docker and the project files:

1. Edit crontab:

   ```bash
   crontab -e
   ```

2. Add a line (update paths to match your installation):

   ```cron
   0 2 * * * cd /path/to/bahmni-standard && /path/to/bahmni-standard/Bahmni_backup_script/bahmni_backup_module.sh full >> /var/log/bahmni_backup.log 2>&1
   ```

Notes:
- Use the full path to the script.
- Redirect stdout/stderr to a logfile for auditing.
- Ensure the user running cron has permission to manage Docker containers.

---

## Directory structure

Example layout (root = bahmni-standard):

```
bahmni-standard/
├── Bahmni_backup_script/
│   ├── bahmni_manager.sh          # Interactive manager
│   ├── bahmni_backup_module.sh    # Backup functions
│   ├── bahmni_restore_module.sh   # Restore functions
│   └── README.md                  # This file
├── bahmni-backups/
│   ├── backup_20251101_063000/
│   ├── backup_20251101_070000/
│   └── ...
├── docker-compose.yml
└── .env
```

Backups are stored under `bahmni-backups/` by default with timestamped folders.

---

## What is backed up

- Databases
  - OpenMRS
  - OpenELIS
  - Odoo
  - Reports
  - Metabase
  - Mart
  - PACS
- Volumes / file stores
  - Patient images
  - Documents
  - Form attachments
  - Lab results
  - Generic file storage used by containers
- Configuration files
  - .env
  - docker-compose.yml
  - Relevant config directories in the compose layout

Backups are gzip-compressed to save space.

---

## Restore behavior and important notes

- Restore operations stop related services before attempting a restore.
- Each database is restored individually using docker-compose flags such as `--no-deps` to avoid bringing up unnecessary services.
- After restoring a database container, the script stops it before proceeding to the next one to ensure isolation.
- After a full restore completes, all services are brought back up.
- Default rotation: the script keeps the most recent 5 backups and removes older ones (configurable inside the script).
- Always verify the backup integrity (file presence and sizes) before starting a restore.

Recommended checklist before restoring:
1. Ensure Docker daemon is running.
2. Confirm you have enough disk space for temporary files and decompression.
3. Make a copy of the most recent backup somewhere safe before performing risky operations.

---

## Troubleshooting

If a restore fails, check the following:

1. Is Docker running?
   ```bash
   systemctl status docker
   ```
2. Does the expected backup folder exist under `bahmni-backups/`?
3. Is there enough free disk space for extraction?
4. Inspect service logs:
   ```bash
   docker compose logs <service-name>
   ```
5. Inspect the manager/backup logs (if you redirected output to a log file in cron).

If you still cannot resolve the issue, gather relevant logs and open an issue in your forked repository (or consult your operation team).

---

## License

MIT

---

## Quick-start recap

From `bahmni-standard`:

```bash
# Clone and install
git clone https://github.com/xmoroix/Bahmni_back_script.git Bahmni_backup_script
chmod +x Bahmni_backup_script/*.sh

# Run interactive manager
./Bahmni_backup_script/bahmni_manager.sh
```

For cron: add a crontab entry that calls `bahmni_backup_module.sh` on a schedule.

