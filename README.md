# Azure VPN Gateway Deployment with Terraform and CI/CD Pipeline

This repository contains Terraform configuration files for deploying an Azure VPN Gateway to establish a site-to-site connection with AWS, along with a GitHub Actions CI/CD pipeline for automated deployment. The pipeline includes validation, security checks, manual approval, and automatic teardown after a demonstration period.

## Table of Contents

- [Introduction](#introduction)
- [Terraform Configuration](#terraform-configuration)
  - [Resources Created](#resources-created)
  - [Variables](#variables)
  - [Outputs](#outputs)
- [CI/CD Pipeline](#cicd-pipeline)
  - [Workflow Triggers](#workflow-triggers)
  - [Pipeline Overview](#pipeline-overview)
  - [Environment Variables and Secrets](#environment-variables-and-secrets)
- [Usage](#usage)
  - [Clone the Repository](#clone-the-repository)
  - [Set Up Azure Credentials](#set-up-azure-credentials)
  - [Configure the Terraform Backend](#configure-the-terraform-backend)
  - [Dependency on Existing VNet](#dependency-on-existing-vnet)
  - [Branch Strategy](#branch-strategy)
  - [Manual Approval](#manual-approval)
  - [Automatic Teardown](#automatic-teardown)
- [Notes](#notes)

## Introduction

This project automates the deployment of an Azure VPN Gateway to establish a site-to-site VPN connection with AWS using Terraform. The configuration includes creating local network gateways, virtual network gateways, and connections that enable communication between Azure and AWS environments.

The GitHub Actions CI/CD pipeline automates validation, security scanning, deployment, and teardown processes.

The CI/CD pipeline is designed to:

- Validate and test Terraform code on pull requests.
- Deploy infrastructure on pushes to specific branches.
- Perform security checks using TFSec.
- Require manual approval before deployment.
- Automatically destroy resources after a demonstration period to minimize costs.

## Terraform Configuration

### Resources Created

The Terraform configuration deploys the following resources:

1. **Azure Local Network Gateways:**

   - **AWS1:**
     - **Name:** `${var.customer_gateway1}_${var.environment}`
     - **Gateway Address:** Defined by `var.customerIP1`
     - **BGP Settings:** ASN `65001`, BGP Peering Address `169.254.21.1`

   - **AWS2:**
     - **Name:** `${var.customer_gateway2}_${var.environment}`
     - **Gateway Address:** Defined by `var.customerIP2`
     - **BGP Settings:** ASN `65001`, BGP Peering Address `169.254.22.1`

2. **Azure Public IP for VPN Gateway:**

   - **Name:** `${var.GatewayIPName}_${var.environment}`
   - **Allocation Method:** Static

3. **Azure Virtual Network Gateway:**

   - **Name:** `${var.vnetgatewayname}_${var.environment}`
   - **Type:** `Vpn`
   - **VPN Type:** Defined by `var.vpntype` (default is `RouteBased`)
   - **SKU:** Defined by `var.gatewaysku` (default is `VpnGw1`)
   - **Enable BGP:** `true`
   - **BGP Settings:** ASN `65002`, APIPA Addresses `["169.254.21.2", "169.254.22.2"]`

4. **Azure Virtual Network Gateway Connections:**

   - **Site2Site_Azure_AWS1:**
     - **Name:** `${var.ConnectionName1}_${var.environment}_Tunnel1`
     - **Type:** `IPsec`
     - **Shared Key:** Provided via GitHub Secrets (`S2SSharedKey`)
     - **Enable BGP:** `true`

   - **Site2Site_Azure_AWS2:**
     - **Name:** `${var.ConnectionName2}_${var.environment}_Tunnel2`
     - **Type:** `IPsec`
     - **Shared Key:** Provided via GitHub Secrets (`S2SSharedKey`)
     - **Enable BGP:** `true`

### Variables

The `variables.tf` file defines the inputs for the Terraform configuration:

- **Azure Credentials:**
  - `azure_subscription_id` (type: `string`, provided via secrets)
  - `azure_client_id` (type: `string`, provided via secrets)
  - `azure_tenant_id` (type: `string`, provided via secrets)

- **Resource Group:**
  - `rg_name` (default: `"Site2Site_rg"`)

- **Location:**
  - `location` (default: `"West US"`)

- **Environment:**
  - `environment` (type: `string`, provided via the Github Workflow pipeline)

- **Customer Gateway Configuration:**
  - `customer_gateway1` (default: `"AWSVGW1"`)
  - `customer_gateway2` (default: `"AWSVGW2"`)
  - `customerIP1` (description: Public IP Address of the Customer VPN Gateway 1)
  - `customerIP2` (description: Public IP Address of the Customer VPN Gateway 2)

- **VPN Gateway Configuration:**
  - `GatewayIPName` (default: `"VnetGatewayIP"`)
  - `vnetgatewayname` (default: `"S2SVnetGate"`)
  - `vpntype` (default: `"RouteBased"`)
  - `gatewaysku` (default: `"VpnGw1"`)
  - `gatewayname` (default: `"gateway_ip"`)

- **VPN Connection Configuration:**
  - `ConnectionName1` (default: `"S2S-AWS-Azure1"`)
  - `ConnectionName2` (default: `"S2S-AWS-Azure2"`)
  - `shared_key` (sensitive, provided via secrets)

### Outputs

The `outputs.tf` file provides the following output after deployment:

- `VnetGateway_Name`: Name of the provisioned Virtual Network Gateway.

## CI/CD Pipeline

The CI/CD pipeline is defined in the GitHub Actions workflow file `.github/workflows/azure-terraform.yml`. It automates the deployment process and ensures code quality and security.

### Workflow Triggers

The pipeline is triggered on:

- **Pull Requests** to the following branches:
  - `development`
  - `production`
  - `testing`
- **Pushes** to the following branches:
  - `development`
  - `production`

### Pipeline Overview

The pipeline consists of two primary jobs:

1. **Validate and Test (`validate-and-test`):**

   - **Checkout Code:** Retrieves the repository code.
   - **Azure Login:** Authenticates to Azure using OpenID Connect (OIDC) with the provided credentials.
   - **Set Up Terraform:** Prepares the environment for Terraform operations.
   - **Set Environment Variable:** Determines the environment (`development`, `production`, or `default`) based on the branch.
   - **Terraform Initialization:** Initializes Terraform with backend configuration for state storage in Azure Blob Storage.
   - **Terraform Validate:** Validates the Terraform configuration syntax.
   - **Terraform Plan:** Creates an execution plan and saves it to `tfplan`.
   - **Show Terraform Plan:** Displays the plan output.
   - **Install TFSec:** Installs TFSec for security scanning.
   - **Run TFSec Security Checks:** Scans the Terraform code for potential security issues.
   - **Skip Apply in Pull Requests:** Ensures that deployment does not occur on pull requests.

2. **Deploy (`deploy`):**

   - **Depends On:** The `validate-and-test` job must succeed.
   - **Runs On:** Not triggered on pull requests.
   - **Repeat Steps:** Similar steps for checkout, authentication, environment setup, and initialization.
   - **Re-run Terraform Plan:** Ensures the plan is up-to-date before applying.
   - **Manual Approval:** Requires manual approval via GitHub Issues before proceeding with the apply step.
   - **Terraform Apply:** Applies the changes as per the plan.
   - **Wait for Demonstration Period:** Pauses execution for 15 minutes (900 seconds) to allow for demonstration or testing.
   - **Terraform Destroy:** Automatically destroys the resources to prevent unnecessary costs.

### Environment Variables and Secrets

The pipeline uses the following secrets and environment variables:

- **Secrets (Stored in GitHub Secrets):**
  - `AZURE_CLIENT_ID`: Azure Service Principal Client ID.
  - `AZURE_TENANT_ID`: Azure Tenant ID.
  - `AZURE_SUBSCRIPTION_ID`: Azure Subscription ID.
  - `S2SSharedKey`: Shared key for the VPN connection.
  - `github_TOKEN`: Automatically provided by GitHub for authentication in workflows.

- **Environment Variables:**
  - `ENVIRONMENT`: Set based on the branch (`development`, `production`, or `default`).

## Usage

### Clone the Repository

```bash
git clone https://github.com/CommittingLearning/Site2Site-Azure-VPNGateway.git
```

### Set Up Azure Credentials

Ensure that the following secrets are added to your GitHub repository under **Settings > Secrets and variables > Actions**:

- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `S2SSharedKey`

These credentials should correspond to an Azure Service Principal with the necessary permissions and the shared key for the VPN connection.

### Configure the Terraform Backend

The Terraform backend is configured to use Azure Blob Storage. Ensure that the storage account and container specified in the `terraform init` command exist, or modify the backend configuration as needed.

- **Storage Account Name:** `tsblobstore11{environment}`
- **Container Name:** `terraform-state`
- **Key:** `Site2Site_VNetGateway_{environment}.tfstate`
- **Resource Group Name:** `Site2Site_rg_{environment}`

### Dependency on Existing VNet

This deployment depends on an existing VNet and subnet. It uses Terraform Remote State Data Source to retrieve outputs from the VNet deployment. Ensure that:

- The VNet and subnets are already deployed and accessible.
- The Terraform state for the VNet is stored remotely and accessible via Terraform Remote State Data Source.
- Adjust the `data.tf` file if necessary to point to the correct remote state.

### Branch Strategy

- **Development Environment:** Use the `development` branch to deploy to the development environment.
- **Production Environment:** Use the `production` branch to deploy to the production environment.
- **Default Environment:** Any other branches will use the `default` environment settings.

### Manual Approval

The pipeline requires manual approval before applying changes:

- A GitHub issue will be created prompting for approval.
- Approvers need to approve the issue to proceed with deployment.

### Automatic Teardown

After a demonstration period of 15 minutes, the pipeline will automatically destroy the deployed resources to prevent unnecessary costs.

## Notes

- **Security Checks:**
  - The pipeline includes security checks using TFSec to identify potential security issues in the Terraform code.

- **State Management:**
  - Terraform state is stored remotely in Azure Blob Storage, ensuring consistency across deployments.
  - The deployment uses a Terraform Remote State Data Source to access outputs from the VNet deployment.

- **Customizations:**
  - Modify the variables in `variables.tf` to change resource names, configurations, and other settings as needed.
  - Ensure that sensitive variables like `shared_key` are handled securely.

- **Testing:**
  - Pull requests to `development`, `production`, or `testing` branches will trigger the validation and testing steps without applying changes.

- **AWS Integration:**
  - The VPN Gateway is configured to connect with AWS using the provided customer gateway IPs and BGP settings.
  - Ensure that the AWS side is properly configured to establish the VPN connection.

- **BGP Settings:**
  - The configuration uses BGP for dynamic routing.
  - Adjust the ASN and BGP peering addresses if necessary to match your network setup.

- **Deployment Order:**
  - **Important:** The VNet Gateway Terraform code must be deployed first.
  - After the Azure VPN Gateway is deployed, apply the AWS VPN configuration using CloudFormation from its respective repository.
  - Then, update this Terraform code to accurately reflect the public IP addresses of the AWS tunnels.
  - This specific order is necessary because AWS CloudFormation throws an error if you attempt to change the public IP address of the customer gateway after it has been created.

---

**Disclaimer:** This repository is accessible in a read only format, and therefore, only the admin has the privileges to perform a push on the branches.