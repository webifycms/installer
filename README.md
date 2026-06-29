# WebifyCMS Installer

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE.md)

The official installer for [WebifyCMS](https://github.com/webifycms/app).

This repository contains the console-based installer to set up WebifyCMS for **Testing** or **Development**.

## Prerequisites

Before running the installer, ensure you have the following installed:

- **Git**: Required for cloning repositories.

### Additional Requirements for Development Mode
- **PHP >= 8.4**: Required for the application to run.
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

## Contributing

Contributions are welcome! Please see the
[main project's contributing guidelines](https://github.com/webifycms/app/blob/main/.github/CONTRIBUTING.md).

## License

WebifyCMS Installer is open-source software licensed under the [MIT license](LICENSE.md).
