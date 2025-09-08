# GitHub Actions workflows

These workflows are [the GitHub way](https://docs.github.com/en/actions/get-started/understand-github-actions) of implementing Continuous Integration and Continuous Delivery (CI/CD).

## Global secrets:

For the workflows to run successfully, a set of repository secrets must be configured **in advance** in the repository's [Settings section](../../../../settings/secrets/actions) (under `Settings > Secrets and variables > Actions`). The following secrets are used by all workflows:

| Secret | Description | Example value |
| --- | --- | --- |
| `AZURE_JSON_CREDENTIALS` | The credentials in (`JSON` format) GitHub Actions uses to [Login With a Service Principal Secret](https://github.com/Azure/login#login-with-a-service-principal-secret) to Azure CLI. This allows it to manage Azure resources. | `{"clientId": "****", "subscriptionId": "****", "clientSecret": "****", "tenantId": "****"}` |
| `AZURE_SUBSCRIPTION_ID` | The unique GUID for the Azure Subscription. | `a1b2c3d4-e5f6-7890-1234-567890abcdef` |

<br>

For more information, see [Using secrets in GitHub Actions](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets) and [Create an Azure service principal with Azure CLI](https://learn.microsoft.com/en-us/cli/azure/azure-cli-sp-tutorial-1?toc=%2Fazure%2Fazure-resource-manager%2Ftoc.json&view=azure-cli-latest&tabs=bash).

## Explanation of each workflow

### [`terraform-webapp.yml`](./terraform-webapp.yml) - WebApp Stack  management with Terraform

This workflow automates the deployment of the web application stack using Terraform. It is designed to be a repeatable and configurable deployment process. It manages the **Load Balancer**, **WebApp**, and **DB** resources located in the [`terraform-webapp`](../../terraform-webapp/) folder.

#### Triggers and filters

The workflow has two triggers:

* `workflow_dispatch`: Allows to manually trigger the workflow form the GitHub [Actions](../../../../actions) UI section of the repository.
* `pull_request`: Automatically triggers the workflow on [Pull Requests](../../../../pulls). The `branches` keyword filters the trigger, so it only runs on pull requests that target the specified branches. The `types` keyword is set to `closed` and `if` condition is set on job level, which means the workflow will trigger only when a pull request is **closed**.

> **_Summary:_** The current setup automatically triggers the workflow only when a pull request to the `dev` or `prod` branches is **closed**. This is useful for running a final apply **after** a successful merge.

#### Functionality

Upon a successful run, this workflow performs the following actions:

* Initializes and plans the Terraform configuration in the [`terraform-webapp/`](../../terraform-webapp/) directory.

* The workflow uses the `vm-init.sh` script via Terraform's `custom_data` to configure the deployed virtual machines. This script handles the initial setup of the web servers, including installing necessary software and configuring the application.

* Allows the user to specify the desired number of web server instances at runtime via an input variable.

* After a successful execution, it saves an artifact - the `tfapply` file, which is the output of the `terraform apply` command. This file can be downloaded and reviewed for up to 30 days after the workflow's completion.

#### Required Secrets

In addition to the [global secrets](#global-secrets) the below ones should also be setup:

| Secret | Description | Example value |
| --- | --- | --- |
| `MY_PERSONAL_IP` | The IP address that will be allowed access to the Cosmos DB. | `212.5.142.47` |
| `WEBAPP_VM_USERNAME` | The administrator username for logging into the Azure Virtual Machines in case needed. | `adminwebapp` |
| `WEBAPP_VM_PASSWORD` | The password for the above administrator account. | `WebAppP@$w0rd!123` |
| `SLACK_WEBHOOK_URL` | **_Optional:_** The webhook URL used to [send Slack alerts](https://docs.slack.dev/messaging/sending-messages-using-incoming-webhooks). | `https://hooks.slack.com/services/T00000000/ B00000000/XXXXXXXXXXXXXXXXXXXXXXXX` |

<br>

---

### [`terraform-bastion.yml`](terraform-bastion.yml) - Bastion Host management with Terraform

This workflow is similar to the [`Terraform WebApp workflow`](#terraform-webappyml---webapp-stack--management-with-terraform). This workflow provides a secure, on-demand SSH access point to the private network where the webapp VMs reside. It manages the automated deployment of an Azure Virtual Machine to implement a [Bastion Host](https://en.wikipedia.org/wiki/Bastion_host), which acts as a jump server for secure access to the other VMs.

#### Trigger and Purpose

This workflow has a **manual trigger only** and is designed for use only when [SSH access](https://en.wikipedia.org/wiki/Secure_Shell) to the WebApp Virtual Machines is **needed**.

#### Functionality

The workflow is responsible for the following actions:

* Initializes and plans the Terraform configuration in the [`terraform-bastion/`](../../terraform-bastion/) directory.

* Deploys a standalone Virtual Machine within the same Virtual Network as the webapp VMs.

* Once deployed, the workflow's output will display the **public IP address** of the bastion host. You can SSH to this IP and, from there, connect to any of the webapp VMs using their internal IP addresses for secure access.

#### Required Secrets

In addition to the [global secrets](#global-secrets), this workflow requires the following secrets to be configured in the repository for SSH credentials:

| Secret | Description | Example value |
| --- | --- | --- |
| `MY_PERSONAL_IP` | The only IP address that will have SSH access to the Bastion Host VM. | `212.5.142.47` |
| `BASTION_USERNAME` | The admin username that would be used for SSH login to the Bastion Host VM. | `adminwebapp` |
| `BASTION_PASSWORD` | The password for the bastion's admin account. | `BastionP@$w0rd!123` |
