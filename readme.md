# OpenVPN Server Setup and Client Configuration Scripts

This repository provides a set of Bash scripts for setting up and configuring an OpenVPN server on Ubuntu, along with tools to generate and manage client configurations. The scripts are designed to be easy to use, with detailed logs and color-coded outputs for better clarity.

## Features

- **Server Setup**: Automates the installation and configuration of an OpenVPN server on Ubuntu.
- **Client Management**: Allows easy generation and signing of client configurations.
- **Detailed Logs**: Provides detailed, step-by-step outputs during the execution of the scripts.
- **Color-Coded Output**: Uses a reusable color palette for improved readability in logs.
- **Customizable**: Scripts are modular and can be adjusted to suit specific needs.

---

---

## Prerequisites

1. A server running **Ubuntu 20.04** or a compatible distribution.
2. **Root access** or sudo privileges.
3. Basic knowledge of Bash scripting (optional, for customization).

---

## Usage

### 1. Clone the Repository
```bash
git clone <repository_url>
cd <repository_name>
```

### 2. Configure the Color Palette
Ensure the `colors.sh` file is correctly sourced in each script:
```bash
source /path/to/colors.sh
```
Update the path as needed.

### 3. Set Up OpenVPN Server

Run the `setup_openvpn_server.sh` script to set up and configure an OpenVPN server:
```bash
sudo bash setup_openvpn_server.sh
```

This script will:
- Install required packages (`openvpn`, `easy-rsa`, etc.).
- Set up the Certificate Authority (CA).
- Generate and configure server certificates.
- Configure the OpenVPN server with a default configuration.
- Enable IP forwarding and firewall rules.
- Start and enable the OpenVPN service.

### 4. Generate Client Configuration

Run the `generate_client_config.sh` script to generate and sign a client configuration:
```bash
sudo bash generate_client_config.sh <client_name>
```

Replace `<client_name>` with the desired client name. This script will:
- Generate a certificate and key for the client.
- Sign the certificate with the CA.
- Create a `.ovpn` file containing the client configuration.

The generated `.ovpn` file will be saved in `~/openvpn-clients/`.

---

## Files and Scripts

### `colors.sh`
A reusable color palette used by all scripts to standardize color-coded output.

### `setup_openvpn_server.sh`
Automates the process of installing and configuring an OpenVPN server.

#### Features:
- Installs required packages.
- Sets up the CA and server certificates.
- Configures the OpenVPN server with default settings.
- Enables firewall and IP forwarding rules.
- Starts and enables the OpenVPN service.

#### Usage:
```bash
sudo bash setup_openvpn_server.sh
```

### `generate_client_config.sh`
Generates and signs a client configuration file for OpenVPN.

#### Features:
- Creates a client certificate and key.
- Signs the certificate with the server's CA.
- Generates a `.ovpn` file with embedded certificates and keys.

#### Usage:
```bash
sudo bash generate_client_config.sh <client_name>
```

---

## Outputs

- **Server Logs**: Detailed step-by-step outputs during server setup.
- **Client Configuration**: `.ovpn` files stored in `~/openvpn-clients/` for easy distribution.

---

## Security Note

- Always distribute `.ovpn` files securely to clients.
- Keep your CA private key safe and inaccessible to unauthorized users.
- Regularly update your server to patch vulnerabilities.

---

## Troubleshooting

- **Permission Denied**: Ensure scripts have executable permissions:
  ```bash
  chmod +x setup_openvpn_server.sh generate_client_config.sh
  ```
- **Missing Dependencies**: Make sure required packages (`openvpn`, `easy-rsa`, `ufw`, etc.) are installed.

---

## License

This project is licensed under the [MIT License](LICENSE).

---

## Contributions

Feel free to submit issues, fork the repository, and open pull requests to contribute to the project.

