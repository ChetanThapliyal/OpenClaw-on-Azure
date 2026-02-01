# OpenClaw on Azure

Professional, zero-trust infrastructure deployment for running [OpenClaw](https://openclaw.ai) (The Personal AI Assistant) on Azure using Terraform.

## 🏗 Architecture

This repository provisions a cost-effective, secure environment for running OpenClaw 24/7.

*   **Compute**: Ubuntu 24.04 VM (`Standard_B2s`) - Balance of cost & performance.
*   **Security (Zero-Trust)**:
    *   **Networking**: No public inbound ports (except SSH restricted to your IP).
    *   **Access**: Application accessed securely via **Tailscale** private mesh networking.
    *   **Identity**: VM uses **Managed Identity** to authenticate with Azure services.
    *   **Secret Management**: **Azure Key Vault** stores sensitive API keys. Secrets are never stored in code or Terraform state.
*   **Containerization**: Docker engine included for OpenClaw Sandbox (safe code execution).
*   **Cost Control**: Integrated Azure Budget alerts to prevent billing surprises ($30/mo target).

## 🚀 Deployment Guide

### Prerequisites
*   [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
*   [Terraform](https://developer.hashicorp.com/terraform/install)
*   **Tailscale Auth Key**: Generate one at [login.tailscale.com](https://login.tailscale.com/admin/settings/keys).
*   **AI API Key**: (Gemini/Anthropic/OpenAI) - Get one from your preferred provider (e.g., [aistudio.google.com](https://aistudio.google.com)).

### 1. Configure
Clone the repo and enter the directory:
```bash
git clone https://github.com/your-repo/OpenClaw-on-Azure.git
cd OpenClaw-on-Azure/terraform
```

Create your configuration file:
```bash
cp terraform.tfvars.template terraform.tfvars
```
Edit `terraform.tfvars`:
*   `allowed_ip_address`: Your public IP (verified via `curl ifconfig.me`).
*   `key_vault_name`: **Must be globally unique** (e.g., `openclaw-kv-jdoe99`).
*   `ai_provider`: Set to `gemini` (default), `anthropic`, or `openai`.

### 2. Deploy
Initialize and apply the Terraform configuration:
```bash
terraform init
terraform apply
```
*Review the plan and type `yes`.*

### 3. Upload Secrets (Urgent)
> [!IMPORTANT]
> **Do this immediately** after `terraform apply` finishes. The VM boots and waits for the Tailscale key.
> If you wait too long (or the script fails), simply **reboot the VM** via the Azure Portal or CLI (`az vm restart ...`) to re-trigger the setup.

After Terraform completes, use the green output commands to upload your secrets:
```bash
az keyvault secret set --vault-name YOUR_KV_NAME --name tailscale-auth-key --value "tskey-..."
```

### 4. Extract SSH Key
Terraform stores the private key in its state. **You need this file to log in.**
```bash
terraform output -raw private_key > openclaw_key.pem
chmod 600 openclaw_key.pem
```

### 5. Install OpenClaw (Manual)
The VM will automatically install Docker, Chrome, and Tailscale. You must install OpenClaw yourself:

1.  **SSH into the VM**:
    ```bash
    ssh -i openclaw_key.pem clawadmin@<public-ip>
    ```

2.  **Run the Installer**:
    ```bash
    sudo bash -c "export OPENCLAW_NO_PROMPT=1; curl -fsSL https://openclaw.ai/install.sh | bash"
    ```

3.  **Onboard**:
    Run the interactive wizard to set up your AI provider and channels:
    ```bash
    openclaw onboard
    ```

## 🔌 Accessing OpenClaw


### 2. Connect via Tailscale (Recommended)
Once the installation finishes, OpenClaw joins your Tailscale mesh network.
1.  Open your **Tailscale Dashboard** (or app on your Phone/Laptop).
2.  Look for a machine named `openclaw-azure`.
3.  **Access the Web UI**: Open `http://openclaw-azure:18789` in your browser.
4.  **SSH**: `ssh clawadmin@openclaw-azure` (Requires Tailscale ACL approval. If valid, no key needed. If blocked, check [Auth & ACLs](https://login.tailscale.com/admin/acls)).

### 3. Debugging (Emergency SSH)
If you cannot see the node on Tailscale, connect via the Public IP (restricted to your IP only):
```bash
ssh -i openclaw_key.pem clawadmin@<public-ip>
# Check logs
tail -f /var/log/cloud-init-output.log
```

## 📂 Repository Structure
*   `terraform/`: Main infrastructure code.
    *   `main.tf`: Resources definition.
    *   `cloud-init.yaml`: VM Provisioning script.
    *   `cost.tf`: Budget & Alerting.

## 🛡 Security Notes
*   **SSH Keys**: Terraform generates a new SSH keypair (`openclaw_key.pem`) for this deployment. Keep it safe.
*   **State**: For production usage, configure a remote backend (e.g., Azure Storage) for `terraform.tfstate`.

---
*Built with ❤️ for OpenClaw*
