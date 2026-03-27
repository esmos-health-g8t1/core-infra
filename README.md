# 🏗️ ESMOS Core Infrastructure

> **Mission-Critical Managed Infrastructure for Healthcare Applications**
> 
> This module defines the foundational Azure cloud infrastructure for ESMOS (Electronic Support for Managed Operations Systems). It provides a secure, scalable, and ITIL-compliant baseline for hosting healthcare workloads like Moodle, Odoo, and Peppermint.

---

## 📐 Architecture Overview

The infrastructure follows a hub-and-spoke inspired networking pattern within a single Virtual Network (VNet), ensuring maximum isolation for the database tier while allowing seamless integration for containerized applications.

```mermaid
graph TD
    subgraph Azure-Cloud ["Azure Cloud (Southeast Asia)"]
        subgraph VNet ["Virtual Network (10.0.0.0/16)"]
            ACA_Subnet ["ACA Subnet (10.0.0.0/23)"]
            DB_Subnet ["Postgres Subnet (10.0.2.0/24)"]
            ACI_Subnet ["ACI Subnet (10.0.3.0/24)"]
        end

        subgraph Compute ["Container Apps Tier"]
            ACA_Env ["ACA Managed Environment"]
            UAI ["User Managed Identity"]
            ACA_Env --> ACA_Subnet
        end

        subgraph Data ["Persistence Tier"]
            Postgres ["PostgreSQL Flexible Server"]
            Storage ["Storage Account (Azure Files)"]
            Postgres --> DB_Subnet
        end

        subgraph Security ["Security & Governance"]
            KV ["Azure Key Vault"]
            ACR ["Azure Container Registry"]
            OIDC ["GitHub OIDC (Workload Identity)"]
        end

        subgraph Ops ["Observability"]
            LAW ["Log Analytics Workspace"]
            Grafana ["Azure Managed Grafana (Optional)"]
        end

        UAI -- "Pulls Image" --> ACR
        UAI -- "Fetches Secrets" --> KV
        ACA_Env -- "Mounts" --> Storage
        ACA_Env -- "Database Connection" --> Postgres
        OIDC -- "Federated Identity" --> UAI
        UAI -- "Logs to" --> LAW
    end
```

---

## 🛠️ Core Components

| Component | Resource | Purpose |
| :--- | :--- | :--- |
| **Identity** | `azurerm_user_assigned_identity` | Unified identity for all service interactions. |
| **Networking** | `azurerm_virtual_network` | Isolated VNet with delegated subnets for ACA, Postgres, and ACI jobs. |
| **Compute** | `azurerm_container_app_environment` | Serverless container hosting with VNet integration. |
| **Database** | `azurerm_postgresql_flexible_server` | Managed DB with Private DNS, per-app dedicated users, and automated backups. |
| **Registry** | `azurerm_container_registry` | Private artifact hosting for Docker images. |
| **Secrets** | `azurerm_key_vault` | Zero-manual-secret policy via Terraform auto-population (16 secrets). |
| **Monitoring**| `azurerm_log_analytics_workspace`| Centralized log aggregation for diagnostic audits. |

---

## 🔐 Secret Management Strategy

This infrastructure implements a **Zero-Manual-Secret** policy. 

1. **Auto-Population**: Terraform automatically writes resource connection strings, admin credentials, and registry paths directly into **Azure Key Vault**.
2. **Runtime Retrieval**: GitHub Actions workflows do not store static secrets; instead, they authenticate via **Workload Identity Federation (OIDC)** and use the `az cli` to fetch secrets directly from Key Vault during deployment.

---

## 🚀 Getting Started

### Prerequisites
- [Terraform](https://www.terraform.io/downloads) (>= 1.5.0)
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- Active Azure Subscription

### 1. Initialization
```powershell
az login
terraform init
```

### 2. Planning & Deployment
Validate the infrastructure state and apply changes:
```powershell
terraform plan -out=infra.plan
terraform apply infra.plan
```

### 3. Verification
Once deployed, check the **Outputs** for the Key Vault name and follow the [Secret Migration Guide](../docs/secrets.md) to link application workflows.

---

## 🛡️ Security & Compliance
- **Private Access Only**: The PostgreSQL server has no public IP and is strictly internal to the `postgres-subnet`.
- **Least-Privilege Database Access**: Each app (Odoo, Moodle, Peppermint) uses a dedicated Postgres user scoped to its own database only.
- **Infrastructure-as-Code (IaC)**: All changes are tracked, auditable, and version-controlled.
- **Role-Based Access Control (RBAC)**: Least-privilege permissions assigned via Managed Identities.
- **Health-Grade Resilience**: Consumption-based scaling ensures availability under varying medical portal loads.

---

## 📝 Planned Enhancements
- [ ] **Azure Managed Grafana**: Full activation for real-time performance dashboards.
- [ ] **Firewall Aggregation**: Integration of Azure Front Door for L7 protection.
- [ ] **Disaster Recovery**: Cross-region storage replication for HIPAA/ITIL high-availability compliance.

---
*Maintained by the ESMOS Infrastructure Team.*
