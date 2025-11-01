#!/bin/bash

###############################################################################
# Bahmni Restore Module
# Description: Functions for restoring Bahmni components
###############################################################################

# Source environment
source .env 2>/dev/null || true

###############################################################################
# Helper Functions
###############################################################################

is_service_running() {
    local service_name=$1
    docker compose ps "$service_name" --status running 2>/dev/null | grep -q "$service_name"
}

wait_for_service() {
    local service_name=$1
    local max_wait=60
    local wait_time=0
    
    echo "    Waiting for ${service_name}..."
    
    while [ $wait_time -lt $max_wait ]; do
        if is_service_running "${service_name}"; then
            sleep 5
            echo -e "${GREEN}    ✓ ${service_name} ready${NC}"
            return 0
        fi
        sleep 2
        wait_time=$((wait_time + 2))
    done
    
    echo -e "${RED}    ✗ Timeout waiting for ${service_name}${NC}"
    return 1
}

stop_service() {
    local service_name=$1
    local max_wait=30
    local wait_time=0
    
    echo "    Stopping ${service_name}..."
    docker compose stop "$service_name"
    
    while [ $wait_time -lt $max_wait ]; do
        if ! is_service_running "${service_name}"; then
            echo -e "${GREEN}    ✓ ${service_name} stopped${NC}"
            return 0
        fi
        sleep 2
        wait_time=$((wait_time + 2))
    done
    
    echo -e "${RED}    ✗ Failed to stop ${service_name}${NC}"
    return 1
}

stop_all_services() {
    echo "  Stopping all services..."
    docker compose stop
    sleep 5
    echo -e "${GREEN}  ✓ All services stopped${NC}"
}

start_single_service() {
    local service_name=$1
    echo "    Starting ${service_name} only (no dependencies)..."
    # Use --no-deps to prevent starting dependent services
    docker compose up -d --no-deps "$service_name"
}

###############################################################################
# Individual Restore Functions
###############################################################################

restore_openmrs_db() {
    local backup_dir=$1
    local backup_file=$(ls "${backup_dir}"/openmrs_db_*.sql.gz 2>/dev/null | head -1)
    
    if [ ! -f "$backup_file" ]; then
        echo -e "${YELLOW}  No OpenMRS backup found${NC}"
        return 0
    fi
    
    echo "  Restoring OpenMRS database..."
    
    # Start ONLY the database service without dependencies
    start_single_service "openmrsdb"
    
    if ! wait_for_service "openmrsdb"; then
        echo -e "${RED}  ✗ Failed to start OpenMRS DB${NC}"
        return 1
    fi
    
    # Additional wait for MySQL to be fully ready
    sleep 10
    
    echo "    Dropping and recreating database..."
    docker compose exec -T openmrsdb mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" \
        -e "DROP DATABASE IF EXISTS ${OPENMRS_DB_NAME}; CREATE DATABASE ${OPENMRS_DB_NAME};" 2>/dev/null
    
    echo "    Importing database..."
    gunzip < "$backup_file" | \
        docker compose exec -T openmrsdb mysql \
        -u"${OPENMRS_DB_USERNAME}" \
        -p"${OPENMRS_DB_PASSWORD}" \
        "${OPENMRS_DB_NAME}"
    
    # Stop the database service before proceeding
    stop_service "openmrsdb"
    
    echo -e "${GREEN}  ✓ OpenMRS database restored${NC}"
}

restore_openelis_db() {
    local backup_dir=$1
    local backup_file=$(ls "${backup_dir}"/openelis_db_*.sql.gz 2>/dev/null | head -1)
    
    if [ ! -f "$backup_file" ]; then
        echo -e "${YELLOW}  No OpenELIS backup found${NC}"
        return 0
    fi
    
    echo "  Restoring OpenELIS database..."
    
    start_single_service "openelisdb"
    
    if ! wait_for_service "openelisdb"; then
        echo -e "${RED}  ✗ Failed to start OpenELIS DB${NC}"
        return 1
    fi
    
    sleep 10
    
    echo "    Importing database..."
    gunzip < "$backup_file" | \
        docker compose exec -T openelisdb psql \
        -U "${OPENELIS_DB_USER}" \
        -d "${OPENELIS_DB_NAME}" 2>/dev/null
    
    stop_service "openelisdb"
    
    echo -e "${GREEN}  ✓ OpenELIS database restored${NC}"
}

restore_odoo_db() {
    local backup_dir=$1
    local backup_file=$(ls "${backup_dir}"/odoo_db_*.sql.gz 2>/dev/null | head -1)
    
    if [ ! -f "$backup_file" ]; then
        echo -e "${YELLOW}  No Odoo backup found${NC}"
        return 0
    fi
    
    echo "  Restoring Odoo database..."
    
    start_single_service "odoodb"
    
    if ! wait_for_service "odoodb"; then
        echo -e "${RED}  ✗ Failed to start Odoo DB${NC}"
        return 1
    fi
    
    sleep 10
    
    echo "    Importing database..."
    gunzip < "$backup_file" | \
        docker compose exec -T odoodb psql \
        -U "${ODOO_DB_USER}" \
        -d postgres 2>/dev/null
    
    stop_service "odoodb"
    
    echo -e "${GREEN}  ✓ Odoo database restored${NC}"
}

restore_reports_db() {
    local backup_dir=$1
    local backup_file=$(ls "${backup_dir}"/reports_db_*.sql.gz 2>/dev/null | head -1)
    
    if [ ! -f "$backup_file" ]; then
        echo -e "${YELLOW}  No Reports backup found${NC}"
        return 0
    fi
    
    echo "  Restoring Reports database..."
    
    start_single_service "reportsdb"
    
    if ! wait_for_service "reportsdb"; then
        echo -e "${RED}  ✗ Failed to start Reports DB${NC}"
        return 1
    fi
    
    sleep 10
    
    echo "    Dropping and recreating database..."
    docker compose exec -T reportsdb mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" \
        -e "DROP DATABASE IF EXISTS ${REPORTS_DB_NAME}; CREATE DATABASE ${REPORTS_DB_NAME};" 2>/dev/null
    
    echo "    Importing database..."
    gunzip < "$backup_file" | \
        docker compose exec -T reportsdb mysql \
        -u"${REPORTS_DB_USERNAME}" \
        -p"${REPORTS_DB_PASSWORD}" \
        "${REPORTS_DB_NAME}"
    
    stop_service "reportsdb"
    
    echo -e "${GREEN}  ✓ Reports database restored${NC}"
}

restore_metabase_db() {
    local backup_dir=$1
    local backup_file=$(ls "${backup_dir}"/metabase_db_*.sql.gz 2>/dev/null | head -1)
    
    if [ ! -f "$backup_file" ]; then
        echo -e "${YELLOW}  No Metabase backup found${NC}"
        return 0
    fi
    
    echo "  Restoring Metabase database..."
    
    start_single_service "metabasedb"
    
    if ! wait_for_service "metabasedb"; then
        echo -e "${RED}  ✗ Failed to start Metabase DB${NC}"
        return 1
    fi
    
    sleep 10
    
    echo "    Importing database..."
    gunzip < "$backup_file" | \
        docker compose exec -T metabasedb psql \
        -U "${METABASE_DB_USER}" \
        -d postgres 2>/dev/null
    
    stop_service "metabasedb"
    
    echo -e "${GREEN}  ✓ Metabase database restored${NC}"
}

restore_mart_db() {
    local backup_dir=$1
    local backup_file=$(ls "${backup_dir}"/mart_db_*.sql.gz 2>/dev/null | head -1)
    
    if [ ! -f "$backup_file" ]; then
        echo -e "${YELLOW}  No Mart backup found${NC}"
        return 0
    fi
    
    echo "  Restoring Mart database..."
    
    start_single_service "martdb"
    
    if ! wait_for_service "martdb"; then
        echo -e "${RED}  ✗ Failed to start Mart DB${NC}"
        return 1
    fi
    
    sleep 10
    
    echo "    Importing database..."
    gunzip < "$backup_file" | \
        docker compose exec -T martdb psql \
        -U "${MART_DB_USERNAME}" \
        -d postgres 2>/dev/null
    
    stop_service "martdb"
    
    echo -e "${GREEN}  ✓ Mart database restored${NC}"
}

restore_pacs_dbs() {
    local backup_dir=$1
    local dcm4chee_backup=$(ls "${backup_dir}"/dcm4chee_db_*.sql.gz 2>/dev/null | head -1)
    local pacs_backup=$(ls "${backup_dir}"/pacs_integration_db_*.sql.gz 2>/dev/null | head -1)
    
    if [ ! -f "$dcm4chee_backup" ]; then
        echo -e "${YELLOW}  No PACS backup found${NC}"
        return 0
    fi
    
    echo "  Restoring PACS databases..."
    
    start_single_service "pacsdb"
    
    if ! wait_for_service "pacsdb"; then
        echo -e "${RED}  ✗ Failed to start PACS DB${NC}"
        return 1
    fi
    
    sleep 10
    
    echo "    Importing DCM4CHEE database..."
    gunzip < "$dcm4chee_backup" | \
        docker compose exec -T pacsdb psql \
        -U "${DCM4CHEE_DB_USERNAME}" \
        -d postgres 2>/dev/null
    
    echo "    Importing PACS Integration database..."
    gunzip < "$pacs_backup" | \
        docker compose exec -T pacsdb psql \
        -U "${PACS_INTEGRATION_DB_USERNAME}" \
        -d postgres 2>/dev/null
    
    stop_service "pacsdb"
    
    echo -e "${GREEN}  ✓ PACS databases restored${NC}"
}

restore_volumes() {
    local backup_dir=$1
    
    echo "  Restoring Docker volumes..."
    
    for volume_archive in "${backup_dir}"/*_*.tar.gz; do
        if [ -f "${volume_archive}" ]; then
            filename=$(basename "${volume_archive}")
            
            if [[ "$filename" == bahmni_config_*.tar.gz ]] || [[ "$filename" == bahmni-config_*.tar.gz ]]; then
                continue
            fi
            
            volume_name=$(echo "$filename" | sed -E 's/_[0-9]{8}_[0-9]{6}\.tar\.gz$//')
            
            echo "    Restoring volume: ${volume_name}"
            
            docker volume create "${volume_name}" > /dev/null 2>&1 || true
            
            docker run --rm \
                -v "${volume_name}:/data" \
                -v "$(pwd)/${backup_dir}:/backup:ro" \
                busybox \
                sh -c "rm -rf /data/* /data/..?* /data/.[!.]* 2>/dev/null || true; tar xzf /backup/${filename} -C /data"
            
            echo -e "${GREEN}    ✓ ${volume_name}${NC}"
        fi
    done
    
    echo -e "${GREEN}  ✓ Volumes restored${NC}"
}

restore_all_databases() {
    local backup_dir=$1
    
    echo "  Restoring all databases..."
    restore_openmrs_db "$backup_dir"
    restore_openelis_db "$backup_dir"
    restore_odoo_db "$backup_dir"
    restore_reports_db "$backup_dir"
    restore_metabase_db "$backup_dir"
    restore_mart_db "$backup_dir"
    restore_pacs_dbs "$backup_dir"
    echo -e "${GREEN}  ✓ All databases restored${NC}"
}

###############################################################################
# Main Restore Functions
###############################################################################

full_restore() {
    local backup_dir=$1
    
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Full Restore Started${NC}"
    echo -e "${GREEN}  $(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    
    stop_all_services
    
    restore_openmrs_db "$backup_dir"
    restore_openelis_db "$backup_dir"
    restore_odoo_db "$backup_dir"
    restore_reports_db "$backup_dir"
    restore_metabase_db "$backup_dir"
    restore_mart_db "$backup_dir"
    restore_pacs_dbs "$backup_dir"
    restore_mart_db "$backup_dir"
    restore_volumes "$backup_dir"
    
    echo ""
    echo "  Starting all services..."
    docker compose up -d
    sleep 10
    
    echo ""
    echo -e "${GREEN}✓ Full restore completed!${NC}"
    echo -e "  Services are starting up..."
}

restore_single() {
    local backup_dir=$1
    local component=$2
    
    echo ""
    echo -e "${YELLOW}Restoring ${component}...${NC}"
    echo ""
    
    case $component in
        openmrs)
            stop_all_services
            restore_openmrs_db "$backup_dir"
            docker compose up -d
            ;;
        openelis)
            stop_all_services
            restore_openelis_db "$backup_dir"
            docker compose up -d
            ;;
        odoo)
            stop_all_services
            restore_odoo_db "$backup_dir"
            docker compose up -d
            ;;
        reports)
            stop_all_services
            restore_reports_db "$backup_dir"
            docker compose up -d
            ;;
        metabase)
            stop_all_services
            restore_metabase_db "$backup_dir"
            docker compose up -d
            ;;
        mart)
            stop_all_services
            restore_mart_db "$backup_dir"
            docker compose up -d
            ;;
        pacs)
            stop_all_services
            restore_pacs_dbs "$backup_dir"
            docker compose up -d
            ;;
        volumes)
            stop_all_services
            restore_volumes "$backup_dir"
            docker compose up -d
            ;;
        all_databases)
            stop_all_services
            restore_all_databases "$backup_dir"
            docker compose up -d
            ;;
        *)
            echo -e "${RED}Unknown component: $component${NC}"
            return 1
            ;;
    esac
    
    echo ""
    echo -e "${GREEN}✓ Restore completed!${NC}"
    echo -e "  Services are restarting..."
}