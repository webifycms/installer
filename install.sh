#!/bin/bash

# WebifyCMS Installer Script

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
GRAY='\033[38;5;244m'

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

check_prerequisites() {
    local missing_deps=0

    info "Checking prerequisites..."

    if ! command_exists php; then
        error "php is not installed."
        missing_deps=1
    else
        local php_version=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
        if [[ "$php_version" < "8.4" ]]; then
            error "PHP 8.4 or higher is required. Current version: $php_version"
            missing_deps=1
        fi
    fi

    if ! command_exists composer; then
        error "composer is not installed."
        missing_deps=1
    fi

    if [ $missing_deps -ne 0 ]; then
        error "Please install the missing dependencies and try again."
        exit 1
    fi

    info "All prerequisites met."
}

install_development() {
    check_prerequisites

    local base_dir
    base_dir=$(cd .. && pwd)
    local app_dir="$base_dir/app"
    local ext_base_dir="$base_dir/extensions/ext-base"
    local themes_dir="$base_dir/themes"

    info "Installing in $base_dir..."

    info "Preparing directories..."
    mkdir -p "$base_dir/extensions"
    mkdir -p "$themes_dir"

    info "Cloning repositories..."

    clone_repo() {
        local repo=$1
        local dir=$2
        if [ -d "$dir" ]; then
            warn "Directory $dir already exists, skipping clone."
        else
            git clone "$repo" "$dir"
        fi
    }

    clone_repo "https://github.com/webifycms/app.git" "$app_dir"
    clone_repo "https://github.com/webifycms/ext-base.git" "$ext_base_dir"

    if [ ! -d "$app_dir" ]; then
        error "App directory not found. Clone failed?"
        exit 1
    fi

    if [ ! -f "$app_dir/.env" ]; then
        info "Setting up environment..."
        cp "$app_dir/.env.example" "$app_dir/.env"

        sed -i 's/APP_ENV=.*/APP_ENV=development/' "$app_dir/.env"
        sed -i 's/APP_DEBUG=.*/APP_DEBUG=true/' "$app_dir/.env"

        sed -i '/^DATABASE_/d' "$app_dir/.env"

        info "Environment configured."
    else
        warn ".env already exists, skipping configuration."
    fi

    if [ ! -f "$app_dir/composer.local.json" ]; then
        info "Creating composer.local.json..."
        cp "$app_dir/composer.json" "$app_dir/composer.local.json"

        php -r '
            $path = $argv[1];
            $json = json_decode(file_get_contents($path), true);
            $json["repositories"] = [
                [
                    "type" => "path",
                    "url" => "../extensions/*",
                    "options" => ["symlink" => true]
                ],
                [
                    "type" => "composer",
                    "url" => "https://asset-packagist.org"
                ]
            ];
            file_put_contents($path, json_encode($json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));
        ' "$app_dir/composer.local.json"

        info "composer.local.json created."

        info "Creating composer.local.lock from composer.lock..."
        cp "$app_dir/composer.lock" "$app_dir/composer.local.lock"
    else
        warn "composer.local.json already exists, skipping."
    fi

    if ! grep -q "composer.local.json" "$app_dir/.gitignore" 2>/dev/null; then
        echo "" >> "$app_dir/.gitignore"
        echo "# composer local" >> "$app_dir/.gitignore"
        echo "composer.local.json" >> "$app_dir/.gitignore"
        echo "composer.local.lock" >> "$app_dir/.gitignore"
        info "Added composer.local.json and composer.local.lock to .gitignore."
    fi

    if [ -d "$ext_base_dir" ]; then
        info "Installing ext-base dependencies..."
        cd "$ext_base_dir"
        composer install
    else
        error "ext-base directory not found. Clone failed?"
        exit 1
    fi

    info "Installing app dependencies..."
    cd "$app_dir"
    COMPOSER=composer.local.json composer install

    info "Installation complete!"
    echo ""
    echo -e "  ${GREEN}php -S localhost:8000 -t app/public/${NC}"
    echo ""

    read -p "Do you want to start the development server now? (Y/n): " start_server
    start_server=${start_server:-Y}

    if [[ "$start_server" =~ ^[Yy]$ ]]; then
        info "Starting development server..."
        php -S localhost:8000 -t "$app_dir/public/"
    else
        info "You can start the server later with: php -S localhost:8000 -t app/public/"
    fi
}

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

show_menu
