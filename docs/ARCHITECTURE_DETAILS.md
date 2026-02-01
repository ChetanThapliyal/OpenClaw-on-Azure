# OpenClaw on Azure - Architectural Design & Decisions

This document details the architectural choices, the deployment workflow, and anticipating questions regarding the implementation of OpenClaw on Azure.

## 1. Architectural Decisions & Rationale

### A. Compute: Virtual Machine vs. Containers (AKS/ACA)
**Decision**: Use a simple Ubuntu Virtual Machine (`Standard_B2s`).
*   **Why**: OpenClaw is designed as a **long-running, stateful personal assistant**. It benefits from a persistent filesystem for its workspace/skills.
*   **Trade-off**: While containers (Azure Container Apps) offer "serverless" scaling, they complicate state persistence and "agentic" behaviors (like installing system tools or running local scripts). A VM provides a predictable, persistent "home" for the agent at a very low cost (~$30/mo vs significantly higher for managed K8s/ACA with persistent volumes).

### B. Network Access: Tailscale (Zero Trust) vs. Public IP
**Decision**: Use Tailscale for ingress; Block all public inbound ports (except SSH from specific IP).
*   **Why**: Exposing an AI agent (potentially with shell execution capabilities) to the public internet is high-risk. Tailscale creates a private, encrypted mesh network.
*   **Benefit**: No need to manage SSL certificates, Nginx configs, or complex firewalls. Access is authenticated via user identity (SSO) before packets even reach the VM.
*   **Defense**: "Why not a VPN Gateway?" -> Tailscale is simpler, cheaper (free tier), and requires zero Azure networking infrastructure cost.

### C. Secret Management: Azure Key Vault + Managed Identity
**Decision**: "Zero-Trust" secret injection.
*   **Why**: We strictly avoid storing API keys in `terraform.tfvars`, environment variables, or git.
*   **Mechanism**:
    1.  Terraform creates an empty Key Vault and a User-Assigned Identity.
    2.  The VM is assigned this Identity.
    3.  **Runtime**: The VM logs in (`az login --identity`) and pulls secrets only when needed.
*   **Benefit**: This separates the *infrastructure* (Terraform) from the *configuration* (Secrets). You can rotate keys in Key Vault without redeploying the VM.

### D. Cost Control: Hard Budgets
**Decision**: Implement Azure Consumption Budgets.
*   **Why**: Cloud billing can spiral (e.g., leaving a large instance running).
*   **Mechanism**: A budget alerts at 80% of $30. This provides peace of mind for a personal project.

---

## 2. The Deployment Flow: What happens after `terraform apply`?

When you hit `Enter`, the following orchestration occurs:

1.  **Infrastructure Provisioning (Terraform)**:
    *   Azure creates the Resource Group, VNet, Subnet, and Public IP.
    *   The **Key Vault** and **Managed Identity** are created.
    *   The **Network Security Group** locks down the network.
    *   The **VM** is created, and the `cloud-init` script is attached as user-data.

2.  **OS Boot & Cloud-Init (Azure Fabric)**:
    *   Ubuntu boots up. `cloud-init` detects the user-data script and begins execution.
    *   **Dependencies**: It installs Docker, Chrome, and the Azure CLI.

3.  **Secret Fetching (The "Magic" Step)**:
    *   The script runs `az login --identity`. Azure validates the VM's identity token.
    *   It attempts to fetch `tailscale-auth-key` and `ai-api-key` from the Key Vault.
    *   *Self-Healing*: If you haven't uploaded secrets yet, the script (loop/retry logic) serves as a wait loop or fails gracefully, waiting for you to run the `az keyvault secret set` commands.

4.  **Application Boot**:
    *   Once secrets are obtained, **Tailscale** authenticates and connects the VM to your mesh.
    *   **OpenClaw** installs, configures itself with the AI provider (Gemini/Anthropic), and starts the systemd service.
