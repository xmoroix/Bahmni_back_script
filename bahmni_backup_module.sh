#!/bin/bash

###############################################################################
# Bahmni Backup Module
# Description: Functions for backing up Bahmni components
###############################################################################

# Configuration
BACKUP_BASE_DIR="./bahmni-backups"

# Source environment
source .env 2>/dev/null || true

###############################################################################
# Helper Functions
###############################################################################

is_service_running() {
    local service_name=$1
    docker compose ps "$service_name" --status running 2>/dev/null | grep -q "$service_name"
}

create_backup_dir() {
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_dir="${BACKUP_BASE_DIR}/backup_${timestamp}"
    mkdir -p "${backup_dir}"
    echo "${backup_dir}"
}

###############################################################################
# Individual Backup Functions
###############################################################################

backup_openmrs_db() {
    local backup_dir=$1
    local timestamp=$(basename "$backup_dir" | sed 's/backup_//')
    
    if ! is_service_running "openmrsdb"; then
        echo -e "${RED}  ✗ OpenMRS DB is not running!${NC}"
        return 1
    fi
    
    echo "  Backing up OpenMRS database..."
    docker compose exec -T openmrsdb mysqldump \
        -u"root" \
        -p"${MYSQL_ROOT_PASSWORD}" \
        "${OPENMRS_DB_NAME}" \
        --single-transaction \
        --quick \
        --lock-tables=false \
        > "${backup_dir}/openmrs_db_${timestamp}.sql"
    
    gzip "${backup_dir}/openmrs_db_${timestamp}.sql"
    echo -e "${GREEN}  ✓ OpenMRS database backed up${NC}"
}

backup_openelis_db() {
    local backup_dir=$1
    local timestamp=$(basename "$backup_dir" | sed 's/backup_//')
    
    if ! is_service_running "openelisdb"; then
        echo -e "${YELLOW}  OpenELIS not running, skipping...${NC}"
        return 0
    fi
    
    echo "  Backing up OpenELIS database..."
    docker compose exec -T openelisdb pg_dump \
        -U "${OPENELIS_DB_USER}" \
        -d "${OPENELIS_DB_NAME}" \
        --no-owner \
        --clean \
        > "${backup_dir}/openelis_db_${timestamp}.sql"
    
    gzip "${backup_dir}/openelis_db_${timestamp}.sql"
    echo -e "${GREEN}  ✓ OpenELIS database backed up${NC}"
}

backup_odoo_db() {
    local backup_dir=$1
    local timestamp=$(basename "$backup_dir" | sed 's/backup_//')
    
    if ! is_service_running "odoodb"; then
        echo -e "${YELLOW}  Odoo not running, skipping...${NC}"
        return 0
    fi
    
    echo "  Backing up Odoo database..."
    docker compose exec -T odoodb pg_dump \
        -U "${ODOO_DB_USER}" \
        -d "${ODOO_DB_NAME}" \
        --no-owner \
        --clean \
        > "${backup_dir}/odoo_db_${timestamp}.sql"
    
    gzip "${backup_dir}/odoo_db_${timestamp}.sql"
    echo -e "${GREEN}  ✓ Odoo database backed up${NC}"
}

backup_reports_db() {
    local backup_dir=$1
    local timestamp=$(basename "$backup_dir" | sed 's/backup_//')
    
    if ! is_service_running "reportsdb"; then
        echo -e "${YELLOW}  Reports not running, skipping...${NC}"
        return 0
    fi
    
    echo "  Backing up Reports database..."
    docker compose exec -T reportsdb mysqldump \
        -u"${REPORTS_DB_USERNAME}" \
        -p"${REPORTS_DB_PASSWORD}" \
        "${REPORTS_DB_NAME}" \
        --single-transaction \
        --quick \
        --lock-tables=false \
        > "${backup_dir}/reports_db_${timestamp}.sql"
    
    gzip "${backup_dir}/reports_db_${timestamp}.sql"
    echo -e "${GREEN}  ✓ Reports database backed up${NC}"
}

backup_metabase_db() {
    local backup_dir=$1
    local timestamp=$(basename "$backup_dir" | sed 's/backup_//')
    
    if ! is_service_running "metabasedb"; then
        echo -e "${YELLOW}  Metabase not running, skipping...${NC}"
        return 0
    fi
    
    echo "  Backing up Metabase database..."
    docker compose exec -T metabasedb pg_dump \
        -U "${METABASE_DB_USER}" \
        -d "${METABASE_DB_NAME}" \
        --no-owner \
        --clean \
        > "${backup_dir}/metabase_db_${timestamp}.sql"
    
    gzip "${backup_dir}/metabase_db_${timestamp}.sql"
    echo -e "${GREEN}  ✓ Metabase database backed up${NC}"
}

backup_mart_db() {
    local backup_dir=$1
    local timestamp=$(basename "$backup_dir" | sed 's/backup_//')
    
    if ! is_service_running "martdb"; then
        echo -e "${YELLOW}  Mart not running, skipping...${NC}"
        return 0
    fi
    
    echo "  Backing up Mart database..."
    docker compose exec -T martdb pg_dump \
        -U "${MART_DB_USERNAME}" \
        -d "${MART_DB_NAME}" \
        --no-owner \
        --clean \
        > "${backup_dir}/mart_db_${timestamp}.sql"
    
    gzip "${backup_dir}/mart_db_${timestamp}.sql"
    echo -e "${GREEN}  ✓ Mart database backed up${NC}"
}

backup_pacs_db() {
    local backup_dir=$1
    local timestamp=$(basename "$backup_dir" | sed 's/backup_//')
    
    if ! is_service_running "pacsdb"; then
        echo -e "${YELLOW}  PACS not running, skipping...${NC}"
        return 0
    fi
    
    echo "  Backing up PACS databases..."
    docker compose exec -T pacsdb pg_dump \
        -U "${DCM4CHEE_DB_USERNAME}" \
        -d "${DCM4CHEE_DB_NAME}" \
        --no-owner \
        --clean \
        > "${backup_dir}/dcm4chee_db_${timestamp}.sql"
    
    docker compose exec -T pacsdb pg_dump \
        -U "${PACS_INTEGRATION_DB_USERNAME}" \
        -d "${PACS_INTEGRATION_DB_NAME}" \
        --no-owner \
        --clean \
        > "${backup_dir}/pacs_integration_db_${timestamp}.sql"
    
    gzip "${backup_dir}/dcm4chee_db_${timestamp}.sql"
    gzip "${backup_dir}/pacs_integration_db_${timestamp}.sql"
    echo -e "${GREEN}  ✓ PACS databases backed up${NC}"
}

backup_volumes() {
    local backup_dir=$1
    local timestamp=$(basename "$backup_dir" | sed 's/backup_//')
    
    echo "  Backing up Docker volumes..."
    
    VOLUMES=(
        "bahmni-patient-images"
        "bahmni-document-images"
        "bahmni-clinical-forms"
        "bahmni-lab-results"
        "bahmni-uploaded-files"
        "bahmni-queued-reports"
        "configuration_checksums"
        "dcm4chee-archive"
        "odoofilestore"
        "openmrsdbdata"
        "openelisdbdata"
        "odoodbdata"
        "reportsdbdata"
        "metabase-data"
        "mart-data"
        "pacsdbdata"
    )
    
    for volume in "${VOLUMES[@]}"; do
        if docker volume ls --format "{{.Name}}" | grep -q "^${volume}$"; then
            echo "    Backing up volume: ${volume}"
            docker run --rm \
                -v "${volume}:/data:ro" \
                -v "$(pwd)/${backup_dir}:/backup" \
                busybox \
                tar czf "/backup/${volume}_${timestamp}.tar.gz" -C /data . 2>/dev/null
            echo -e "${GREEN}    ✓ ${volume}${NC}"
        fi
    done
    
    echo -e "${GREEN}  ✓ Volumes backed up${NC}"
}

backup_configs() {
    local backup_dir=$1
    local timestamp=$(basename "$backup_dir" | sed 's/backup_//')
    
    echo "  Backing up configurations..."
    
    cp .env "${backup_dir}/.env"
    cp docker-compose.yml "${backup_dir}/docker-compose.yml"
    
    if [ -d "./bahmni_config" ]; then
        tar czf "${backup_dir}/bahmni_config_${timestamp}.tar.gz" -C . bahmni_config
    fi
    
    if [ -d "./bahmni-config" ]; then
        tar czf "${backup_dir}/bahmni-config_${timestamp}.tar.gz" -C . bahmni-config
    fi
    
    echo -e "${GREEN}  ✓ Configurations backed up${NC}"
}

backup_all_databases() {
    local backup_dir=$1
    
    echo "  Backing up all databases..."
    backup_openmrs_db "$backup_dir"
    backup_openelis_db "$backup_dir"
    backup_odoo_db "$backup_dir"
    backup_reports_db "$backup_dir"
    backup_metabase_db "$backup_dir"
    backup_mart_db "$backup_dir"
    backup_pacs_db "$backup_dir"
    echo -e "${GREEN}  ✓ All databases backed up${NC}"
}

###############################################################################
# Main Backup Functions
###############################################################################

full_backup() {
    local backup_dir=$(create_backup_dir)
    
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Full Backup Started${NC}"
    echo -e "${GREEN}  $(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    
    backup_openmrs_db "$backup_dir"
    backup_openelis_db "$backup_dir"
    backup_odoo_db "$backup_dir"
    backup_reports_db "$backup_dir"
    backup_metabase_db "$backup_dir"
    backup_mart_db "$backup_dir"
    backup_pacs_db "$backup_dir"
    backup_volumes "$backup_dir"
    backup_configs "$backup_dir"
    
    local backup_size=$(du -sh "${backup_dir}" | cut -f1)
    echo ""
    echo -e "${GREEN}✓ Full backup completed!${NC}"
    echo -e "  Location: ${backup_dir}"
    echo -e "  Size: ${backup_size}"
}

backup_single() {
    local component=$1
    local backup_dir=$(create_backup_dir)
    
    echo ""
    case $component in
        openmrs)
            backup_openmrs_db "$backup_dir"
            ;;
        openelis)
            backup_openelis_db "$backup_dir"
            ;;
        odoo)
            backup_odoo_db "$backup_dir"
            ;;
        reports)
            backup_reports_db "$backup_dir"
            ;;
        metabase)
            backup_metabase_db "$backup_dir"
            ;;
        mart)
            backup_mart_db "$backup_dir"
            ;;
        pacs)
            backup_pacs_db "$backup_dir"
            ;;
        volumes)
            backup_volumes "$backup_dir"
            ;;
        configs)
            backup_configs "$backup_dir"
            ;;
        all_databases)
            backup_all_databases "$backup_dir"
            ;;
        *)
            echo -e "${RED}Unknown component: $component${NC}"
            return 1
            ;;
    esac
    
    local backup_size=$(du -sh "${backup_dir}" | cut -f1)
    echo ""
    echo -e "${GREEN}✓ Backup completed!${NC}"
    echo -e "  Location: ${backup_dir}"
    echo -e "  Size: ${backup_size}"
}
