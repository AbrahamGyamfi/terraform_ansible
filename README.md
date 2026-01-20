# project-deployandconfigureawebapp(terraform+ansible)

## Overview

This project demonstrates how to provision an EC2 instance using Terraform and configure a full-stack DevOps Dashboard using Ansible. SSH key-based authentication is used, and all provisioning is automated to reflect industry-standard practices. The application is a production-ready React/Node.js dashboard deployed from GitHub.

## Architecture

### Terraform:
- Creates a **t3.micro** EC2 instance (Amazon Linux 2023)
- Generates a local SSH key (RSA 4096-bit) and registers the public key as an AWS key pair
- Creates a security group allowing:
  - **HTTP (80)** from anywhere
  - **SSH (22)** from specific IP (configurable)
- Uses `data.aws_ami` to dynamically fetch the latest Amazon Linux 2023 AMI
- Creates 30GB EBS volume with encryption at rest
- Tags all resources with standard tags (Project, Owner, Environment, Name)

### Ansible:
- Installs and configures Node.js 18 (via dnf on AL2023)
- Clones application from GitHub: `https://github.com/AbrahamGyamfi/DevOps_deploy.git`
- Installs all dependencies (root, client, server)
- Builds React frontend with production configuration (`VITE_API_URL=/api`)
- Configures PM2 process manager for Node.js backend
- Installs and configures Nginx as reverse proxy:
  - Serves React static files from `/opt/devops-dashboard/client/dist`
  - Proxies API requests (`/api/*`) to Node.js backend on port 5000
- Enables and starts all services with auto-restart on boot

## Prerequisites

- **Terraform** v1.0+
- **Ansible** 2.9+
- **AWS account** with credentials configured (via `aws configure` or environment variables)
- **Region permissions**: eu-west-1 (Ireland)
- **Linux/Mac** or WSL on Windows
- Internet access to reach AWS and install packages

## Folder Structure

```
Terraform_ansible/
│
├── terraform/                  # Terraform configuration
│   ├── main.tf                # Main infrastructure definitions
│   ├── variables.tf           # Variable declarations
│   ├── outputs.tf             # Output values (IP, SSH key path, etc.)
│   ├── terraform.tfvars       # Environment-specific values
│   └── terraform.tfvars.example
│
├── ansible/                    # Ansible configuration
│   ├── ansible.cfg            # Ansible settings
│   ├── inventory.ini          # Auto-generated from Terraform outputs
│   ├── site.yml               # Master playbook
│   ├── roles/
│   │   └── nginx/
│   │       ├── handlers/
│   │       ├── tasks/
│   │       └── templates/
│   └── templates/             # Deleted (GitHub app deployment)
│
├── keys/                       # SSH keys (auto-generated)
│   ├── terraform-ansible-key.pem  # Private key (chmod 400)
│   └── terraform-ansible-key.pub  # Public key
│
├── evidence/                   # Deployment evidence
│   ├── APPLY.txt              # Terraform apply log
│   ├── HTTP_RESPONSE_CURL.txt # HTTP response validation
│   ├── BROWSER_SCREENSHOT.png # Visual proof (manual)
│   └── DESTROY.txt            # Terraform destroy log
│
├── scripts/                    # Automation scripts
│   ├── deploy.sh              # Full deployment automation
│   ├── cleanup.sh             # Infrastructure teardown
│   └── update-inventory.sh    # Inventory generator
│
├── DEPLOYMENT_WORKFLOW.md      # Detailed technical documentation
├── QUICKSTART.md
├── CHECKLIST.md
└── README.md                   # This file
```

## Usage

### 1. Provision Infrastructure

```bash
cd terraform
terraform init
terraform apply -auto-approve | tee ../evidence/APPLY.txt
```

**This will:**
- Create EC2 instance (t3.micro, Amazon Linux 2023)
- Generate RSA 4096-bit SSH key pair
- Create security groups (SSH:22, HTTP:80)
- Configure 30GB encrypted EBS volume
- Output the public IP of the EC2 instance

**Output examples:**
```
instance_public_ip = "34.243.75.237"
ssh_private_key_path = "../keys/terraform-ansible-key.pem"
ssh_user = "ec2-user"
web_url = "http://34.243.75.237"
```

### 2. Generate Inventory for Ansible

```bash
cd ../ansible
chmod +x ../scripts/update-inventory.sh
../scripts/update-inventory.sh
```

**Or use automated deployment:**
```bash
cd ..
chmod +x scripts/*.sh
./scripts/deploy.sh  # Runs Terraform + Ansible automatically
```

### 3. Configure EC2 with Ansible

```bash
ansible-playbook -i inventory.ini site.yml
```

**This will:**
- Install system packages and Node.js 18
- Clone DevOps Dashboard from GitHub
- Run `npm install:all` (installs root, client, server dependencies)
- Build production React app: `VITE_API_URL=/api npm run build`
- Configure PM2 to manage Node.js backend (port 5000)
- Install and configure Nginx:
  - Serves React build from `/opt/devops-dashboard/client/dist`
  - Proxies `/api/*` requests to `http://localhost:5000`
- Enable services to start on boot

**Verify by visiting:** `http://<public_ip>` or running:
```bash
curl http://<public_ip>
curl http://<public_ip>/api/health
```

### 4. Destroy Infrastructure

```bash
cd terraform
terraform destroy -auto-approve | tee ../evidence/DESTROY.txt
```

**This will remove all resources provisioned by Terraform.**

## Evidence

Evidence files are stored in the `evidence/` directory:

- **Webpage deployed**: Screenshot captured at `http://<public_ip>` → `BROWSER_SCREENSHOT.png`
- **Terraform apply**: Complete infrastructure creation log → `APPLY.txt` ✓
- **HTTP validation**: curl response with headers → `HTTP_RESPONSE_CURL.txt` ✓
- **Terraform destroy**: Complete teardown log → `DESTROY.txt`
- **Ansible logs**: Playbook output shows all services installed and running

## Application Stack

**Frontend:**
- React 18 + Vite 5.4.21
- Production build served by Nginx
- API calls to `/api` endpoint

**Backend:**
- Node.js 18.20.8 + Express
- Runs on port 5000 (localhost only)
- Managed by PM2 with auto-restart

**Web Server:**
- Nginx 1.28.0
- Reverse proxy configuration
- Serves static files + proxies API requests

## Security

- SSH key-based authentication (no passwords)
- RSA 4096-bit encryption
- Private key permissions: `chmod 400`
- Security group rules: least privilege
- EBS volume encryption at rest
- Backend isolated on localhost (not publicly accessible)

## Additional Resources

- **Detailed Workflow**: See [DEPLOYMENT_WORKFLOW.md](DEPLOYMENT_WORKFLOW.md) for comprehensive explanations
- **Terraform Docs**: [AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- **Ansible Docs**: [Official Documentation](https://docs.ansible.com/)

---

**Quick Deploy:** Run `./scripts/deploy.sh`  
**Questions?** Check [DEPLOYMENT_WORKFLOW.md](DEPLOYMENT_WORKFLOW.md)
