# Terraform on Azure: Infrastructure as a Code Automation for a Web Stack

This repository presents a solution to a given task for Infrastructure Automation Setup. The project provisions a Load Balancer, a (few) Virtual Machine(s) and a Cosmos Database web application stack on Microsoft Azure using Terraform. This repo exists so I can demonstrate in practice Infrastructure as Code (IaC) and automation with CI/CD GitHub Actions.

## Table of contents

- [Assignment](#objective-definition)
- [Solution Overview](#solution-overview)
- [Usage](#usage)
- [Prerequisites](#prerequisites)
- [Troubleshooting](#troubleshooting)
- [Activity log](#activity-log)

## Task's assignment

<details><summary>

#### Objective definition</h4></summary><br>

This infrastructure automation challenge is designed to assess one's ability to provision and manage cloud-based infrastructure using Infrastructure-as-Code (IaC) principles.

This repo should set up a basic web application stack on **Azure** using **Terraform** as an IaC tool. The stack includes a load balancer, web server(s), and a database running on separate services/instances.

Key requirements include automating the provisioning of a load balancer, web server instances, and a database, all running on separate instances or services. The solution also requires a CI/CD strategy to automate provisioning and deployment, triggered by code changes in the repository.</details>

## Solution overview

The project is organized into three distinct, logical modules to manage different aspects of the infrastructure. Each folder contains its own self-contained Terraform configuration.

* [`terraform-initial-resources/`](./terraform-initial-resources/): Contains the fundamental infrastructure components, including the **_core infrastructure_** Resource Group and Virtual Network. These foundational resources must be deployed **manually** and serve as [prerequisites](#prerequisites) for the other components.

* [`terraform-webapp/`](./terraform-webapp/): Manages the web application's infrastructure, which includes the load balancer, the web server virtual machine(s) and the database. This module is designed for automated deployment via GitHub Actions.

* [`terraform-bastion/`](./terraform-bastion/): A separate, **optional** module for deploying a [Bastion Host](https://en.wikipedia.org/wiki/Bastion_host). This provides a secure [SSH access](https://en.wikipedia.org/wiki/Secure_Shell) to the private web server VM(s) **when needed** for maintenance or debugging. Also designed for automated deployment via GitHub Actions.

### CI/CD with GitHub Actions

This repository leverages [GitHub Actions](../../../actions) to automate the deployment of the web application and the bastion host. Each workflow is designed to be triggered manually, providing controlled and on-demand deployment capabilities. The [task's assignment](#objective-definition) requires _provisioning and deployment, to be triggered by code changes in the repository_, so the GHA (GitHub Actions) workflow that manages that has also the corresponding trigger for automated execution.

More info can be found in the GHA [workflows' README](./.github/workflows/).

## Usage

### Prerequisites

- An active [![Azure Subscription](https://custom-icon-badges.demolab.com/badge/Azure_Subscription-black?logo=msazure&logoColor=blue)](https://azure.microsoft.com/) and appropriate permissions.

- [![Azure CLI](https://custom-icon-badges.demolab.com/badge/Azure_CLI-black?logo=msazure&logoColor=blue)](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed and [authenticated](https://learn.microsoft.com/en-us/cli/azure/authenticate-azure-cli?view=azure-cli-latest).

- [![Terraform](https://img.shields.io/badge/Terraform-v1.13+-844FBA?labelColor=black&logo=terraform&logoColor=844FBA)](https://developer.hashicorp.com/terraform/install) installed.

- [![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-black?logo=github-actions&logoColor=blue)](https://github.com/features/actions) enabled with set repository secrets.

### Steps

1. **Clone this repo**

    ```bash
    git clone https://github.com/peshhe/terraform-azure.git && cd terraform-azure/
    ```

2. **Manual Deployment of the Core Infrastructure** to set up the foundation for the project:

   ```bash
   cd terraform-initial-resources/
   terraform init
   terraform apply -var subscription_id="your-azure-subscription-id"
   ```

3. **Configure GitHub Repository Secrets:**
Add the necessary Azure credentials and SSH credentials to your GitHub repository's [secrets settings](../../../settings/secrets/actions) described in [workflows' README](./.github/workflows/).

4. **Automated Deployment of Webapp Stack:**
Once the core infrastructure is in place and repository secrets are configured, navigate to the ["Actions" tab](../../../actions) in your GitHub repository and manually run the [WebApp stack deployment workflow](../../../actions/workflows/terraform-webapp.yml). You can specify the desired number of VM instances as an input to the workflow execution.

5. **(Optional) Deploy Bastion Host:** If SSH access to the webapp VMs is required, trigger the [bastion deployment workflow](../../../actions/workflows/terraform.bastion.yml) manually to deploy a secure jump host. After successfull execution:

    - **Connect to Bastion**: Use the credentials stored in `BASTION_USERNAME` and `BASTION_PASSWORD` secrets.

        ```bash
        ssh <BASTION_USERNAME>@<BASTION_PUBLIC_IP>
        ```

    - **Connect to WebApp VMs:**

        ```bash
        # From the bastion host, connect to webapp VMs using their internal IPs
        ssh <WEBAPP_ADMIN_USERNAME>@<WEBAPP_VM_INTERNAL_IP>
        ```

        > **_Note:_** Bastion host is connected to the same VNet as webapp VMs. All connections use internal IP addresses for enhanced security.

## Troubleshooting

### Common Issues

#### Workflow Failures

- Verify all required repository secrets are configured as described in [this `README.md`](./.github/workflows/README.md).
- Check Azure Service Principal permissions and credentials.
- Ensure core infrastructure is deployed **before** webapp/bastion!

#### VM Connection Issues

- Check if bastion host is properly deployed.
- Check (your) IP address, provided with access to the bastion.
- Confirm VM internal IP addresses.

#### Terraform State Issues

- Ensure state backend is properly configured.
- Verify Azure credentials are valid and Azure CLI authentication is successful.

#### Logs and Monitoring

- **GitHub Actions Logs**: Check workflow execution logs in the Actions tab
- **Azure Activity Log**: Monitor resource deployment status in Azure Portal

## Activity log

Last updated | Changes
--- | ---
4 Sep 2025 | Upload of **_core infrastructure_** files in [`terraform-initial-resources/`](./terraform-initial-resources/) directory.
5 Sep 2025 | Upload of **_Bastion Host_** files in [`terraform-bastion/`](terraform-bastion/) directory.
6 Sep 2025 | Upload of **_WebApp Stack_** files in [`terraform-webapp/`](terraform-webapp/) directory.
6 Sep 2025 | Upload of **_GitHub Actions workflow_** files in [`.github/workflows/`](.github/workflows/) directory.
6 Sep 2025 | Misc fixes of GHA workflows.
8 Sep 2025 | Added a trigger for [`terraform-webapp.yml`](.github/workflows/terraform-webapp.yml) workflow that detects merged pull requests.
8 Sep 2025 | Added [this](README.md) and [this](.github/workflows/README.md) `README.md` files
9 Sep 2025 | Added description of Bastion deployment and usage.
9 Sep 2025 | Added the [Troubleshooting](#troubleshooting) and [Activity log](#activity-log) sections.
