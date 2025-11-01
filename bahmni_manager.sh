#!/bin/bash

###############################################################################
# Bahmni Docker Backup/Restore Manager
# Description: Interactive menu for managing Bahmni backups and restores
# Usage: ./bahmni_manager.sh
###############################################################################

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Change to bahmni-standard root directory (parent of script directory)
cd "$(dirname "$SCRIPT_DIR")"

# Source the backup and restore modules
source "${SCRIPT_DIR}/bahmni_backup_module.sh"
source "${SCRIPT_DIR}/bahmni_restore_module.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

###############################################################################
# Menu Functions
###############################################################################

show_header() {
    clear
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Bahmni Backup/Restore Manager${NC}"
    echo -e "${GREEN}  Date: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
}

main_menu() {
    while true; do
        show_header
        echo -e "${CYAN}Main Menu:${NC}"
        echo ""
        echo "  1) Backup"
        echo "  2) Restore"
        echo "  3) List Backups"
        echo "  4) Delete Old Backups"
        echo "  0) Exit"
        echo ""
        echo -ne "${YELLOW}Choose an option: ${NC}"
        read -r choice
        
        case $choice in
            1)
                backup_menu
                ;;
            2)
                restore_menu
                ;;
            3)
                list_backups
                read -p "Press Enter to continue..."
                ;;
            4)
                delete_backups_menu
                ;;
            0)
                echo -e "${GREEN}Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                sleep 2
                ;;
        esac
    done
}

backup_menu() {
    while true; do
        show_header
        echo -e "${CYAN}Backup Menu:${NC}"
        echo ""
        echo "  1) Full Backup (All databases + volumes + configs)"
        echo "  2) Backup All Databases Only"
        echo "  3) Backup OpenMRS Database"
        echo "  4) Backup OpenELIS Database"
        echo "  5) Backup Odoo Database"
        echo "  6) Backup Reports Database"
        echo "  7) Backup Metabase Database"
        echo "  8) Backup Mart Database"
        echo "  9) Backup PACS Databases"
        echo "  10) Backup All Volumes Only"
        echo "  11) Backup Configurations Only"
        echo "  0) Back to Main Menu"
        echo ""
        echo -ne "${YELLOW}Choose an option: ${NC}"
        read -r choice
        
        case $choice in
            1)
                echo -e "${YELLOW}Starting full backup...${NC}"
                full_backup
                read -p "Press Enter to continue..."
                ;;
            2)
                echo -e "${YELLOW}Backing up all databases...${NC}"
                backup_single "all_databases"
                read -p "Press Enter to continue..."
                ;;
            3)
                echo -e "${YELLOW}Backing up OpenMRS...${NC}"
                backup_single "openmrs"
                read -p "Press Enter to continue..."
                ;;
            4)
                echo -e "${YELLOW}Backing up OpenELIS...${NC}"
                backup_single "openelis"
                read -p "Press Enter to continue..."
                ;;
            5)
                echo -e "${YELLOW}Backing up Odoo...${NC}"
                backup_single "odoo"
                read -p "Press Enter to continue..."
                ;;
            6)
                echo -e "${YELLOW}Backing up Reports...${NC}"
                backup_single "reports"
                read -p "Press Enter to continue..."
                ;;
            7)
                echo -e "${YELLOW}Backing up Metabase...${NC}"
                backup_single "metabase"
                read -p "Press Enter to continue..."
                ;;
            8)
                echo -e "${YELLOW}Backing up Mart...${NC}"
                backup_single "mart"
                read -p "Press Enter to continue..."
                ;;
            9)
                echo -e "${YELLOW}Backing up PACS...${NC}"
                backup_single "pacs"
                read -p "Press Enter to continue..."
                ;;
            10)
                echo -e "${YELLOW}Backing up all volumes...${NC}"
                backup_single "volumes"
                read -p "Press Enter to continue..."
                ;;
            11)
                echo -e "${YELLOW}Backing up configurations...${NC}"
                backup_single "configs"
                read -p "Press Enter to continue..."
                ;;
            0)
                return
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                sleep 2
                ;;
        esac
    done
}

restore_menu() {
    while true; do
        show_header
        echo -e "${CYAN}Restore Menu:${NC}"
        echo ""
        
        # List available backups
        BACKUP_BASE_DIR="./bahmni-backups"
        if [ -d "$BACKUP_BASE_DIR" ]; then
            backups=($(ls -dt "${BACKUP_BASE_DIR}"/backup_* 2>/dev/null || true))
            
            if [ ${#backups[@]} -eq 0 ]; then
                echo -e "${RED}No backups found!${NC}"
                read -p "Press Enter to continue..."
                return
            fi
            
            echo "Available backups:"
            for i in "${!backups[@]}"; do
                backup_name=$(basename "${backups[$i]}")
                backup_date=$(echo "$backup_name" | sed 's/backup_//' | sed 's/_/ /')
                backup_size=$(du -sh "${backups[$i]}" | cut -f1)
                echo "  $((i+1))) $backup_date (Size: $backup_size)"
            done
            echo ""
            echo "  0) Back to Main Menu"
            echo ""
            echo -ne "${YELLOW}Select backup to restore: ${NC}"
            read -r backup_choice
            
            if [ "$backup_choice" == "0" ]; then
                return
            fi
            
            if [ "$backup_choice" -ge 1 ] && [ "$backup_choice" -le "${#backups[@]}" ]; then
                selected_backup="${backups[$((backup_choice-1))]}"
                restore_options_menu "$selected_backup"
            else
                echo -e "${RED}Invalid selection!${NC}"
                sleep 2
            fi
        else
            echo -e "${RED}Backup directory not found!${NC}"
            read -p "Press Enter to continue..."
            return
        fi
    done
}

restore_options_menu() {
    local backup_dir=$1
    
    while true; do
        show_header
        echo -e "${CYAN}Restore Options:${NC}"
        echo ""
        echo -e "Selected backup: ${GREEN}$(basename "$backup_dir")${NC}"
        echo ""
        echo "  1) Full Restore (All databases + volumes)"
        echo "  2) Restore All Databases Only"
        echo "  3) Restore OpenMRS Database Only"
        echo "  4) Restore OpenELIS Database Only"
        echo "  5) Restore Odoo Database Only"
        echo "  6) Restore Reports Database Only"
        echo "  7) Restore Metabase Database Only"
        echo "  8) Restore Mart Database Only"
        echo "  9) Restore PACS Databases Only"
        echo "  10) Restore Volumes Only"
        echo "  0) Back"
        echo ""
        echo -ne "${YELLOW}Choose an option: ${NC}"
        read -r choice
        
        case $choice in
            1)
                echo -e "${RED}WARNING: This will replace ALL current data!${NC}"
                echo -ne "${YELLOW}Type 'yes' to confirm: ${NC}"
                read -r confirm
                if [ "$confirm" == "yes" ]; then
                    full_restore "$backup_dir"
                    read -p "Press Enter to continue..."
                fi
                ;;
            2)
                echo -e "${RED}WARNING: This will replace ALL databases!${NC}"
                echo -ne "${YELLOW}Type 'yes' to confirm: ${NC}"
                read -r confirm
                if [ "$confirm" == "yes" ]; then
                    restore_single "$backup_dir" "all_databases"
                    read -p "Press Enter to continue..."
                fi
                ;;
            3)
                restore_single "$backup_dir" "openmrs"
                read -p "Press Enter to continue..."
                ;;
            4)
                restore_single "$backup_dir" "openelis"
                read -p "Press Enter to continue..."
                ;;
            5)
                restore_single "$backup_dir" "odoo"
                read -p "Press Enter to continue..."
                ;;
            6)
                restore_single "$backup_dir" "reports"
                read -p "Press Enter to continue..."
                ;;
            7)
                restore_single "$backup_dir" "metabase"
                read -p "Press Enter to continue..."
                ;;
            8)
                restore_single "$backup_dir" "mart"
                read -p "Press Enter to continue..."
                ;;
            9)
                restore_single "$backup_dir" "pacs"
                read -p "Press Enter to continue..."
                ;;
            10)
                restore_single "$backup_dir" "volumes"
                read -p "Press Enter to continue..."
                ;;
            0)
                return
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                sleep 2
                ;;
        esac
    done
}

list_backups() {
    show_header
    echo -e "${CYAN}Available Backups:${NC}"
    echo ""
    
    BACKUP_BASE_DIR="./bahmni-backups"
    if [ -d "$BACKUP_BASE_DIR" ]; then
        backups=($(ls -dt "${BACKUP_BASE_DIR}"/backup_* 2>/dev/null || true))
        
        if [ ${#backups[@]} -eq 0 ]; then
            echo -e "${YELLOW}No backups found.${NC}"
        else
            for backup in "${backups[@]}"; do
                backup_name=$(basename "$backup")
                backup_date=$(echo "$backup_name" | sed 's/backup_//' | sed 's/_/ - /')
                backup_size=$(du -sh "$backup" | cut -f1)
                echo -e "  ${GREEN}$backup_date${NC}"
                echo -e "    Location: $backup"
                echo -e "    Size: $backup_size"
                
                # Show what's in the backup
                db_count=$(ls "$backup"/*.sql.gz 2>/dev/null | wc -l || echo "0")
                vol_count=$(ls "$backup"/*.tar.gz 2>/dev/null | wc -l || echo "0")
                echo -e "    Contains: ${db_count} databases, ${vol_count} volumes"
                echo ""
            done
        fi
    else
        echo -e "${YELLOW}Backup directory does not exist yet.${NC}"
    fi
    echo ""
}

delete_backups_menu() {
    show_header
    echo -e "${CYAN}Delete Old Backups:${NC}"
    echo ""
    
    BACKUP_BASE_DIR="./bahmni-backups"
    if [ -d "$BACKUP_BASE_DIR" ]; then
        backups=($(ls -dt "${BACKUP_BASE_DIR}"/backup_* 2>/dev/null || true))
        
        if [ ${#backups[@]} -eq 0 ]; then
            echo -e "${YELLOW}No backups found.${NC}"
            read -p "Press Enter to continue..."
            return
        fi
        
        echo "Current backups (${#backups[@]} total):"
        for i in "${!backups[@]}"; do
            backup_name=$(basename "${backups[$i]}")
            backup_date=$(echo "$backup_name" | sed 's/backup_//' | sed 's/_/ /')
            backup_size=$(du -sh "${backups[$i]}" | cut -f1)
            echo "  $((i+1))) $backup_date (Size: $backup_size)"
        done
        echo ""
        echo "  a) Keep only last 5 backups"
        echo "  b) Keep only last 3 backups"
        echo "  c) Delete specific backup"
        echo "  0) Cancel"
        echo ""
        echo -ne "${YELLOW}Choose an option: ${NC}"
        read -r choice
        
        case $choice in
            a)
                rotate_backups 5
                read -p "Press Enter to continue..."
                ;;
            b)
                rotate_backups 3
                read -p "Press Enter to continue..."
                ;;
            c)
                echo -ne "${YELLOW}Enter backup number to delete: ${NC}"
                read -r backup_num
                if [ "$backup_num" -ge 1 ] && [ "$backup_num" -le "${#backups[@]}" ]; then
                    backup_to_delete="${backups[$((backup_num-1))]}"
                    echo -e "${RED}WARNING: This will permanently delete backup:${NC}"
                    echo -e "  $(basename "$backup_to_delete")"
                    echo -ne "${YELLOW}Type 'yes' to confirm: ${NC}"
                    read -r confirm
                    if [ "$confirm" == "yes" ]; then
                        rm -rf "$backup_to_delete"
                        echo -e "${GREEN}✓ Backup deleted${NC}"
                    else
                        echo -e "${YELLOW}Cancelled${NC}"
                    fi
                else
                    echo -e "${RED}Invalid backup number!${NC}"
                fi
                read -p "Press Enter to continue..."
                ;;
            0)
                return
                ;;
            *)
                echo -e "${RED}Invalid option!${NC}"
                sleep 2
                ;;
        esac
    else
        echo -e "${YELLOW}Backup directory does not exist yet.${NC}"
        read -p "Press Enter to continue..."
    fi
}

rotate_backups() {
    local max_backups=$1
    BACKUP_BASE_DIR="./bahmni-backups"
    
    echo -e "${YELLOW}Rotating backups (keeping last ${max_backups})...${NC}"
    
    cd "${BACKUP_BASE_DIR}"
    backups=($(ls -dt backup_* 2>/dev/null || true))
    backup_count=${#backups[@]}
    
    if [ ${backup_count} -gt ${max_backups} ]; then
        for ((i=max_backups; i<backup_count; i++)); do
            echo "  Deleting: ${backups[$i]}"
            rm -rf "${backups[$i]}"
        done
        deleted_count=$((backup_count - max_backups))
        echo -e "${GREEN}✓ Deleted ${deleted_count} old backup(s)${NC}"
    else
        echo -e "${GREEN}✓ No rotation needed (${backup_count}/${max_backups} backups)${NC}"
    fi
    
    cd - > /dev/null
}

###############################################################################
# Main Execution
###############################################################################

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Error: Docker is not running!${NC}"
    exit 1
fi

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${RED}Error: .env file not found!${NC}"
    echo -e "${YELLOW}Make sure you run this script from bahmni-standard directory${NC}"
    exit 1
fi

# Start main menu
main_menu