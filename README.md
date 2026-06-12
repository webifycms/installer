# WebifyCMS Installer

This repository contains the installer for WebifyCMS.
It currently provides a console-based installer to set up WebifyCMS for **Testing** or **Development**.

## Prerequisites

Before running the installer, ensure you have the following installed:

- **Git**: Required for cloning repositories.

### Additional Requirements for Development Mode
- **PHP >= 8.4**: Required for local dependency management.
- **Composer V2**: Required for installing PHP dependencies.

## Usage

1. Create a directory for the installation:
   ```bash
   # Example:
   mkdir ~/webifycms
   cd ~/webifycms
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

5. Follow the on-screen prompts to continue the installation.

## Troubleshooting

- **Permission Denied**: Ensure you have run `chmod +x install.sh`.
- **Missing Dependencies**: The script will check for required tools. Install any missing tools as prompted.
