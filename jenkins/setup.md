# Jenkins Controller & Agent Setup Guide

## 1. Infrastructure Provisioning (Terraform)
We used Terraform to provision the necessary infrastructure in AWS:
- **Jenkins Controller:** Deployed as an EC2 instance in the **Public Subnet** (from Assignment 3). Port `8080` (HTTP) is restricted to our specific IP address, and Port `22` is open for SSH.
- **Jenkins Agent:** Deployed as a secondary EC2 instance in the **Private Subnet**. Its security group strictly allows SSH access *only* from the Jenkins Controller's security group.

## 2. Server Configuration (`user_data`)
Both servers were configured automatically upon boot using bash scripts:
- **Controller Setup:** The `user_data` script updated packages and installed **Java 21** (required by modern Jenkins), the **Jenkins LTS** package via the official Debian repository, **Git**, **Docker**, the **AWS CLI**, and **Terraform**. Docker was enabled and the `ubuntu` and `jenkins` users were added to the `docker` group.
- **Agent Setup:** The agent script installed **Java 21**, **Git**, and **Docker** so it possesses all the necessary tools to pull code, run pipeline steps, and build containers.

## 3. Jenkins UI Initial Setup
After the Controller booted:
1. We unlocked Jenkins using the `/var/lib/jenkins/secrets/initialAdminPassword`.
2. Selected "Install suggested plugins".
3. Created an initial Admin user and confirmed the Jenkins URL (IP address).

## 4. Plugin Installation
Navigated to **Manage Jenkins > Plugins** and installed the assignment-required plugins:
- Pipeline
- Git
- GitHub Branch Source
- Docker Pipeline
- Credentials Binding
- Pipeline Utility Steps
- SonarQube Scanner
- Blue Ocean

## 5. Agent Connection
To enforce the controller-agent architecture, we linked the private Agent to the Controller:
1. Created a Global Credential (`SSH Username with private key`) containing the `.pem` key.
2. Added a new Node named `linux-agent`.
3. Set the remote root to `/home/ubuntu/jenkins_agent`.
4. Assigned the label `linux-agent`.
5. Connected via **Launch agents via SSH**, using the Agent's internal Private IP (`10.0.10.218`).
6. Set the Controller ("Built-In Node") executors to `0` to guarantee all pipelines execute purely on the `linux-agent`.

## 6. Global Credentials & GitHub Integration
Navigated to **Manage Jenkins > Credentials** and stored all sensitive tokens (AWS, GitHub PAT, Slack Webhook, Docker Hub).
Finally, we configured the **GitHub Server** in the System Configuration, attaching the PAT to allow Jenkins to read repositories and post commit status checks.
