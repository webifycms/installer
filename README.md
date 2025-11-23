# WebifyCMS Installer

This repository contains the installer for WebifyCMS. It currently provides a console-based installer to set up WebifyCMS for **Testing** or **Development** environments.

## Prerequisites

Before running the installer, ensure you have the following installed:

- **Git**: Required for cloning repositories.
- **Docker**: Required for running the application containers.

### Additional Requirements for Development Mode
- **PHP**: Required for local dependency management.
- **Composer**: Required for installing PHP dependencies.

## Usage

1. Create a directory for the installation:
   ```bash
   # Example:
   mkdir ~/webifycms-stack
   cd ~/webifycms-stack
   ```

2. Clone this installer repository:
   ```bash
   git clone https://github.com/webifycms/installer.git
   cd installer
   ```

3. Make the script executable:
   ```bash
   chmod +x install.sh
   ```

4. Run the installer:
   ```bash
   ./install.sh
   ```

4. Follow the on-screen prompts to select your installation mode.

## Installation Modes

### 1. Development
Designed for developers who want to contribute to WebifyCMS or its extensions.
- Installs in the parent directory.
- Clones the main app, core extensions and default theme (`ext-base`, `ext-admin`, `ext-user`, `ext-site`, `theme-green`) into separate directories.
- Configures the environment for development (`APP_ENVIRONMENT=dev`, `APP_DEBUG=true`, `APP_COOKIE_VALIDATION_KEY=<random>`).
- Runs `composer install` to set up PHP dependencies.
- Starts Docker containers.
- **URL**: `http://localhost:<NGINX_PORT>` (Port defined in `.env`)

## Troubleshooting

- **Permission Denied**: Ensure you have run `chmod +x install.sh`.
- **Missing Dependencies**: The script will check for required tools. Install any missing tools as prompted.
- **Docker Issues**: Ensure the Docker daemon is running before starting the installer.
