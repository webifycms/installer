#!/bin/bash

# WebifyCMS Installer Script

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
GRAY='\033[1;30m'

# Function to print messages
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check prerequisites
check_prerequisites() {
    local mode=$1
    local missing_deps=0

    info "Checking prerequisites for $mode mode..."

    if ! command_exists git; then
        error "git is not installed."
        missing_deps=1
    fi

    if ! command_exists docker; then
        error "docker is not installed."
        missing_deps=1
    fi

    if [ "$mode" == "Development" ]; then
        if ! command_exists php; then
            error "php is not installed."
            missing_deps=1
        fi

        if ! command_exists composer; then
            error "composer is not installed."
            missing_deps=1
        fi
    fi

    if [ $missing_deps -ne 0 ]; then
        error "Please install the missing dependencies and try again."
        exit 1
    fi

    info "All prerequisites met."
}

# Development Flow
install_development() {
    check_prerequisites "Development"

    local install_dir=".."

    info "Installing in parent directory..."
    cd "$install_dir"

    # Clone repositories
    info "Cloning repositories..."
    
    # Helper to clone if not exists
    clone_repo() {
        local repo=$1
        local dir=$2
        if [ -d "$dir" ]; then
            warn "Directory $dir already exists, skipping clone."
        else
            git clone "$repo" "$dir"
        fi
    }

    clone_repo "https://github.com/webifycms/app.git" "app"
    clone_repo "https://github.com/webifycms/ext-base.git" "ext-base"
    clone_repo "https://github.com/webifycms/ext-admin.git" "ext-admin"
    clone_repo "https://github.com/webifycms/ext-user.git" "ext-user"
    clone_repo "https://github.com/webifycms/ext-site.git" "ext-site"
    clone_repo "https://github.com/webifycms/theme-green.git" "theme-green"

    # Checkout local branches
    info "Checking out local branches..."

    # Function to checkout local branch
    checkout_local() {
        local dir=$1
        local required=$2
        
        if [ -d "$dir" ]; then
            cd "$dir"
            info "Checking $dir..."
            
            # Fetch all branches to ensure we know about remote branches
            git fetch origin

            if git show-ref --verify --quiet "refs/remotes/origin/local"; then
                info "Switching to local branch in $dir..."
                git checkout local
            else
                if [ "$required" == "true" ]; then
                    error "Critical: 'local' branch not found in $dir. Aborting."
                    exit 1
                else
                    warn "'local' branch not found in $dir. Staying on main."
                fi
            fi
            cd ..
        else
            warn "Directory $dir not found."
        fi
    }

    checkout_local "app" "true"
    checkout_local "ext-base" "false"
    checkout_local "ext-admin" "false"
    checkout_local "ext-user" "false"
    checkout_local "ext-site" "false"
    checkout_local "theme-green" "false"

    # Setup App
    if [ -d "app" ]; then
        cd app
        info "Setting up environment..."
        if [ ! -f ".env" ]; then
            cp .env.sample .env
            
            # Update .env values
            sed -i 's/APP_ENVIRONMENT=prod/APP_ENVIRONMENT=dev/' .env
            sed -i 's/APP_DEBUG=false/APP_DEBUG=true/' .env
            
            # Generate random key for cookie validation
            # Using openssl if available, fallback to other methods if needed, but openssl is standard in most linux/docker envs
            # or use /dev/urandom
            cookie_key=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
            # Escape special characters if any (though alphanumeric shouldn't have issues)
            sed -i "s/APP_COOKIE_VALIDATION_KEY=/APP_COOKIE_VALIDATION_KEY=$cookie_key/" .env
        else
            warn ".env already exists, skipping configuration."
        fi


        info "Installing dependencies..."
        composer install

        info "Setting permissions..."
        # Create directories if they don't exist to avoid errors
        mkdir -p runtime public/assets
        chmod -R 0777 runtime public/assets

        # Database Configuration
        info "Database Configuration"
        echo "You can either manually enter database credentials or let the script generate them."
        read -p "Do you want to auto-generate database credentials? (Y/n): " auto_generate_db
        auto_generate_db=${auto_generate_db:-Y}

        if [[ "$auto_generate_db" =~ ^[Yy]$ ]]; then
            db_name="webifycms"
            db_user="webify"
            # Generate random passwords
            db_password=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
            db_root_password=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
            
            info "Generated Credentials:"
            echo "Database Name: $db_name"
            echo "Database User: $db_user"
            echo "Database Password: $db_password"
            echo "Database Root Password: $db_root_password"
        else
            read -p "Enter Database Name [webifycms]: " db_name
            db_name=${db_name:-webifycms}
            
            read -p "Enter Database User [webify]: " db_user
            db_user=${db_user:-webify}
            
            read -s -p "Enter Database Password: " db_password
            echo ""
            
            read -s -p "Enter Database Root Password: " db_root_password
            echo ""
        fi

        # Update .env with DB credentials
        # Use a delimiter that is unlikely to be in the password, e.g., |
        sed -i "s|DATABASE_NAME=|DATABASE_NAME=$db_name|" .env
        sed -i "s|DATABASE_USER=|DATABASE_USER=$db_user|" .env
        sed -i "s|DATABASE_PASSWORD=|DATABASE_PASSWORD=$db_password|" .env
        sed -i "s|DATABASE_ROOT_PASSWORD=|DATABASE_ROOT_PASSWORD=$db_root_password|" .env

        info "Starting Docker containers..."
        # Option to run docker compose up
        read -p "Do you want to start the containers now? (Y/n): " start_docker
        start_docker=${start_docker:-Y}

        if [[ "$start_docker" =~ ^[Yy]$ ]]; then
            docker compose up -d
        else
            info "Skipping Docker start."
        fi
        
        # Get port from .env
        local port=$(grep NGINX_PORT= .env | cut -d '=' -f2)
        local base_url=$(grep APP_BASE_URL= .env | cut -d '=' -f2)
        
        info "Installation complete!"
        info "You can access the application at http://${base_url}:${port}"
    else
        error "App directory not found. Clone failed?"
        exit 1
    fi
}

# Main Menu
show_menu() {
    echo "Welcome to WebifyCMS Installer"
    echo "Please select the installation purpose:"
    echo "1) Development"
    echo -e "${GRAY}2) Production (Not ready yet)${NC}"
    
    read -p "Enter your choice [1-2]: " choice

    case $choice in
        1)
            install_development
            ;;
        2)
            warn "Production installation is not yet supported."
            exit 0
            ;;
        *)
            error "Invalid choice."
            exit 1
            ;;
    esac
}

# Run
show_menu
