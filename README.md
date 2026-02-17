# OpenClaw on Azure

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Terraform](https://img.shields.io/badge/Terraform-1.0%2B-purple)](https://www.terraform.io/)
[![Azure](https://img.shields.io/badge/Cloud-Azure-blue)](https://azure.microsoft.com/)

Professional, **Zero-Trust** infrastructure deployment for running [OpenClaw](https://openclaw.ai) (The Personal AI Assistant) on Azure. This repository provides a secure, cost-effective, and reproducible environment for hosting your own autonomous AI agent.

---

## 📖 Table of Contents

- [Overview](#-overview)
- [Architecture](#-architecture)
- [Prerequisites](#-prerequisites)
- [Installation & Setup](#-installation--setup)
- [Configuration](#-configuration)
- [Usage](#-usage)
- [Security](#-security)
- [Contributing](#-contributing)

---

## 🔭 Overview

OpenClaw is an advanced AI assistant capable of executing code, browsing the web, and managing tasks. Running it on your local machine is great, but running it in the cloud ensures 24/7 availability and a standardized environment.

This project automates the provisioning of a secure Azure environment tailored for OpenClaw. It prioritizes:

- **Security**: Zero inbound public ports (except strictly controlled SSH).
- **Cost Efficiency**: specific VM sizing (`Standard_B2s`) and budget alerts (~$30/mo).
- **Privacy**: No secrets in code; Identity-based access to Key Vault.
- **Ease of Use**: Automated bootstrapping with Terraform.

---

## 🏗 Architecture

The infrastructure is designed as a "Zero Trust" island.

```mermaid
graph LR
    User[You (Laptop/Phone)] -->|Tailscale Trusted| VM[Azure VM (OpenClaw)]
    VM -->|Managed Identity| KV[Azure Key Vault]
    VM -.->|Blocked| Internet[Public Internet (Inbound)]
    VM -->|Out| Internet2[Public Internet (Outbound)]
```

### Key Components

- **Compute**: `Standard_B2s` Ubuntu 24.04 VM. Chosen for its balance of burstable CPU performance and low cost.
- **Networking**:
  - **No Public Inbound Access**: Traditional ports (80, 443) are closed.
  - **Tailscale Mesh VPN**: Access to the OpenClaw web UI and SSH is granted exclusively via your private Tailscale network.
  - **Emergency SSH**: Port 22 is open *only* to your specific public IP address for debugging if Tailscale fails.
- **Identity & Secrets**:
  - **Managed Identity**: The VM utilizes a User-Assigned Managed Identity to authenticate with Azure services without hardcoded credentials.
  - **Key Vault**: Stores sensitive API keys (OpenAI/Anthropic/Gemini) and Tailscale auth keys.

---

## 📋 Prerequisites

Before you begin, ensure you have the following tools and accounts:

1. **Azure Account**: A valid subscription.
2. **Azure CLI**: [Install Guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli).
3. **Terraform**: [Install Guide](https://developer.hashicorp.com/terraform/downloads).
4. **Tailscale Account**: [Sign up](https://tailscale.com). You will need an **Auth Key** from the [Admin Console](https://login.tailscale.com/admin/settings/keys).
5. **AI API Key**: An API key from your preferred provider (Google Gemini, Anthropic Claude, or OpenAI).

---

## 🚀 Installation & Setup

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/OpenClaw-on-Azure.git
cd OpenClaw-on-Azure/terraform
```

### 2. Configure Infrastructure

Create your variable definitions file:

```bash
cp terraform.tfvars.template terraform.tfvars
```

Edit `terraform.tfvars` with your specific details:

- `allowed_ip_address`: Your current public IP (find it via `curl ifconfig.me`).
- `key_vault_name`: A **globally unique** name (e.g., `openclaw-kv-yourname`).
- `admin_username`: Your preferred SSH username (default: `clawadmin`).

### 3. Deploy with Terraform

Initialize and apply the configuration. This will create the Resource Group, VM, Key Vault, and Networking components.

```bash
terraform init
terraform apply
```

*Review the plan and type `yes` to confirm.*

### 4. Upload Secrets (Critical Step)

> [!IMPORTANT]
> **Perform this immediately after Terraform completes.** The VM will attempt to fetch these secrets on boot.

Use the Azure CLI to populate your Key Vault with the necessary secrets.

```bash
# Upload Tailscale Auth Key
az keyvault secret set --vault-name <your-key-vault-name> --name tailscale-auth-key --value "tskey-auth-..."

# Upload AI API Key (Optional auto-configuration)
az keyvault secret set --vault-name <your-key-vault-name> --name ai-api-key --value "sk-..."
```

*Note: If you miss the timing window, simply restart the VM via the Azure Portal or CLI (`az vm restart ...`) to re-trigger the setup script.*

### 5. Access the VM

Terraform generates a dedicated SSH key for this deployment.

```bash
# Extract the private key
terraform output -raw private_key > openclaw_key.pem
chmod 600 openclaw_key.pem

# SSH into the VM (using your specific IP)
ssh -i openclaw_key.pem clawadmin@<public-ip-from-output>
```

---

## ⚙️ Configuration details

### Environment Variables

Environment variables for the OpenClaw agent are managed within the VM. You can typically find configuration in `~/.config/openclaw/` or pass them during the installation wizard.

### Terraform Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `resource_group_name` | Name of the Azure Resource Group | `openclaw-rg` |
| `location` | Azure Region | `centralindia` |
| `vm_size` | Azure VM SKU | `Standard_B2s` |
| `key_vault_name` | Name of the Key Vault (Must be unique) | *(Required)* |
| `allowed_ip_address` | CIDR for SSH access | *(Required)* |

---

## 🔌 Usage

Once deployed and the secrets are synced, the VM will automatically join your Tailscale network.

1. **Connect**: Ensure your local machine is connected to Tailscale.
2. **Access Web UI**: Navigate to `http://openclaw-azure:18789` in your browser.
3. **SSH via Tailscale**: You can also SSH directly using the hostname `ssh clawadmin@openclaw-azure` (subject to your Tailscale ACLs).

### Installing OpenClaw (Manual Step)

While the infrastructure is automated, the agent itself is best installed manually to ensure you have the latest version and can configure it interactively.

1. SSH into the VM.
2. Run the installer:

    ```bash
    curl -fsSL https://openclaw.ai/install.sh | bash
    ```

3. Follow the on-screen wizard to pair with your preferred AI provider.

---

## 🛡 Security

- **Zero Open Ports**: We rely entirely on Tailscale for secure, authenticated ingress.
- **Managed Identity**: No static credentials are stored on the VM disk for Azure setup.
- **Least Privilege**: The VM's identity has permission *only* to read secrets from the specific Key Vault created by Terraform.
- **State Management**: For production use, verify you are not committing `terraform.tfstate` or `openclaw_key.pem` to version control. The `.gitignore` is configured to prevent this.

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository.
2. Create a feature branch (`git checkout -b feature/amazing-feature`).
3. Commit your changes (`git commit -m 'Add some amazing feature'`).
4. Push to the branch (`git push origin feature/amazing-feature`).
5. Open a Pull Request.

---

*Built with ❤️ for the OpenClaw Community*
