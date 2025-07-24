# SysOpsProject

## 📌 Project Overview

This project demonstrates how to build a **scalable and cost-effective AWS infrastructure** for hosting a simple image slideshow web application.  
It combines best practices for **availability**, **automation**, **monitoring** and **cost control**.

---

## 🗂️ Project Structure

```
SysOpsProject/
├── bootstrap-backend/
│   └── main.tf
├── infrastructure/
│   ├── ALB_Config.tf
│   ├── Cloudfront.tf
│   ├── EC2Autoscaling.tf
│   ├── MonitoringAlerts.tf
│   ├── Route53_DNS.tf
│   ├── S3Assets.tf
│   ├── VPC_Network.tf
│   ├── install_webapp.sh
│   ├── images/
│   │   └── (your .jpg images)
│   ├── provider.tf
│   ├── terraform.tfvars
│   └── variables.tf
└── README.md
```

---

## 🧱 Architecture

**Key AWS Components:**

| Component        | Purpose                                                               |
|------------------|------------------------------------------------------------------------|
| **S3**           | Hosts the image assets securely                                        |
| **CloudFront**   | Distributes static content globally with caching                       |
| **EC2 ASG**      | Runs the app across x86 and ARM instances with autoscaling             |
| **ALB**          | Load balances HTTP/HTTPS traffic to healthy EC2 instances              |
| **Route53**      | DNS management for your domain                                         |
| **ACM**          | SSL certificates for encrypted HTTPS                                   |
| **CloudWatch**   | Monitoring, dashboards, and alerts                                     |
| **IAM**          | Role-based least-privilege access                                      |

---

## 🛠️ Tech Stack / AWS Services Used

| AWS Service       | Function                                                |
|-------------------|----------------------------------------------------------|
| **Terraform**     | Infrastructure as Code (IaC)                             |
| **EC2 + ALB**     | Web app hosting                                          |
| **S3 + CloudFront** | Static asset delivery and caching                     |
| **CloudWatch**    | Metrics, dashboards, alerts                              |
| **IAM**           | Access control and security                              |

---

## 🚀 How to Deploy

> Prerequisites: Terraform installed

1. **Clone the repository**
   ```bash
   git clone https://github.com/cristivlad21/SysOpsProject.git
   cd SysOpsProject/bootstrap-backend
   ```

2. **Deploy Terraform backend (S3 remote state)**
   ```bash
   terraform init
   terraform apply
   ```

3. **Switch to main infrastructure**
   ```bash
   cd ../infrastructure
   ```

4. **Configure variables**
   - Edit `terraform.tfvars` with your AWS region, domain, and email

5. **Add your images**
   - Place `.jpg` files into the local `images/` folder

6. **Initialize and apply**
   ```bash
   terraform init
   terraform apply
   ```

7. **Access the app**

---

## 🔁 Automation & Monitoring

- EC2 instances scale automatically based on CPU load
- HTTPS enabled via ACM (TLS certificate)
- CloudWatch alarms for:
  - High CPU
  - Unhealthy EC2 instances
- Static assets are cached and globally delivered via CloudFront
- S3 bucket is private and accessible only through CloudFront OAI

---

## 🧹 Cleanup

To delete the full infrastructure:

```bash
cd infrastructure
terraform destroy

cd ../bootstrap-backend
terraform destroy
```

> This removes all AWS resources, including the Terraform backend bucket.

---

## ⚠️ Domain Setup Notes

- You must own the domain you set in `terraform.tfvars`
- If you don’t use Route53, manually update your DNS with your provider
- Set A or CNAME records pointing to your ALB or CloudFront endpoint