# Trendstore Application Deployment on AWS EKS

This repository contains the end-to-end configuration and setup for deploying the **Trendstore (Trendify)** web application on an Amazon EKS (Elastic Kubernetes Service) cluster. The architecture leverages **Terraform** for Infrastructure as Code (IaC), **Docker** for containerization, **Jenkins** for automated CI/CD pipelines, and **Prometheus & Grafana** for monitoring and observability.

---

## 🏗️ Architecture Overview

1. **Infrastructure Provisioning**: Terraform creates AWS VPC, Subnets, IGW, Route Tables, Security Groups, and an EC2 instance pre-configured with Nginx, Docker, and Jenkins.
2. **Containerization**: Docker builds the Nginx-based frontend container image (`ragulgandhi/trend-app`) and pushes it to Docker Hub.
3. **Orchestration**: AWS EKS cluster created via `eksctl` hosts the application deployment and `LoadBalancer` service.
4. **CI/CD Pipeline**: Jenkins pipeline triggers automatically via GitHub Webhooks upon code changes to build, push, and deploy updates.
5. **Observability**: Prometheus & Grafana stack deployed via Helm for cluster and pod metrics.

---

## 🛠️ Prerequisites & Tools

Ensure the following tools are installed on your management machine:
- [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [Terraform](https://developer.hashicorp.com/terraform/downloads) (>= 1.4.0)
- [Docker](https://docs.docker.com/get-docker/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [eksctl](https://eksctl.io/installation/)
- [Helm](https://helm.sh/docs/intro/install/)

---

## 🚀 Getting Started

### 1. Provision Base Infrastructure (Terraform)

Navigate to the `terraform/` directory to initialize and deploy the EC2 instance and network configuration.

```bash
cd terraform

# Initialize providers (AWS, TLS, Local)
terraform init

# Plan infrastructure changes
terraform plan

# Apply infrastructure provision
terraform apply --auto-approve
```

> **Outputs**: Note down the generated `Public_IP` and SSH private key created locally.

---

### 2. Docker Containerization

To manually build and test the application container image:

```bash
# Build Docker image
docker build -t ragulgandhi/trend-app:latest .

# Run locally to verify (Port 8081)
docker run -d -p 8081:80 --name trend-con ragulgandhi/trend-app:latest

# Login & Push to Docker Hub
docker login -u ragulgandhi
docker push ragulgandhi/trend-app:latest
```

---

### 3. Kubernetes (AWS EKS) Deployment

#### A. Create the EKS Cluster
```bash
eksctl create cluster \
  --name ragul \
  --region ap-south-1 \
  --node-type t2.medium \
  --nodes 2 \
  --nodes-min 2 \
  --nodes-max 4
```

Verify cluster connectivity:
```bash
eksctl get cluster --region ap-south-1
kubectl get nodes
```

#### B. Deploy Application Manifests
Apply the Deployment and LoadBalancer Service configurations stored under `k8s/`:

```bash
kubectl apply -f k8s/trend.yml

# Verify pods and service status
kubectl get pods
kubectl get svc trend-app-service
```

Access the application via the `EXTERNAL-IP` URL provided by the LoadBalancer service on port `3000`.

---

### 4. Observability Setup (Prometheus & Grafana)

Install the `kube-prometheus-stack` using Helm:

```bash
# Add Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create namespace and install stack
kubectl create namespace monitoring
helm install monitoring prometheus-community/kube-prometheus-stack --namespace monitoring
```

Expose dashboards locally via port forwarding:

```bash
# Grafana (Port 3000)
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80 --address 0.0.0.0

# Prometheus (Port 9090)
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090 --address 0.0.0.0
```

---

### 5. CI/CD Automated Pipeline (Jenkins)

1. Access your Jenkins server at `http://<EC2_PUBLIC_IP>:8080`.
2. Create a new Pipeline job pointed to this GitHub repository.
3. Configure the trigger: **GitHub hook trigger for GITScm polling**.
4. Configure a GitHub Webhook pointing to: `http://<EC2_PUBLIC_IP>:8080/github-webhook/`.
5. Any push to `main` (e.g., updating `Dockerfile` or source code) will trigger an automated build and zero-downtime deployment to EKS.

---

## 📂 Repository Structure

```text
.
├── terraform/          # Infrastructure as Code (VPC, Security Groups, EC2, SSH Keys)
│   ├── main.tf
│   ├── provider.tf
│   └── output.tf
├── k8s/                # Kubernetes Deployment & Service Manifests
│   └── trend.yml
├── dist/               # Application static build files
├── Dockerfile          # Nginx container image spec
├── Jenkinsfile         # CI/CD Declarative Pipeline definition
└── README.md           # Project Documentation
```