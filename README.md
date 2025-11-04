
# 🧩 **Amazon Clone – End-to-End DevOps Project on AWS**

<img width="1395" height="499" alt="image" src="https://github.com/user-attachments/assets/81ee820c-728a-4b12-abcd-223175c87343" />


## 📖 **Overview**
This project showcases the deployment of an **Amazon Clone application** through a **fully automated DevOps CI/CD pipeline** built on **AWS**.  
It combines **Terraform**, **Jenkins**, **ArgoCD**, and multiple AWS services — including **EKS**, **ALB**, **Route 53**, and **ACM** — to demonstrate how modern, cloud-native infrastructures are built and managed using **GitOps principles**.

---

## 🧱 **Key Components**
| Layer | Tool / Service | Purpose |
|-------|----------------|----------|
| **Infrastructure as Code (IaC)** | Terraform | Provisions VPC and EKS cluster |
| **Continuous Integration (CI)** | Jenkins | Builds Docker image, runs tests, pushes to DockerHub |
| **Continuous Delivery (CD)** | ArgoCD | Automates application deployment to EKS |
| **Container Registry** | DockerHub | Stores versioned container images |
| **Networking & DNS** | AWS Route 53 | Domain registration and DNS resolution |
| **Load Balancing** | AWS ALB Ingress Controller | Routes external traffic into EKS |
| **TLS / HTTPS** | AWS ACM | Manages SSL certificates |
| **Security** | SonarQube, Trivy | Code and image vulnerability scanning |
| **Monitoring** | Prometheus, Grafana | Observability and cluster health monitoring |

---

## ⚙️ **Architecture Flow**
**Developer Commit → GitHub → Jenkins → DockerHub → GitOps Repo → ArgoCD → AWS EKS → ALB → Route 53 / ACM → Prometheus / Grafana**

---

## 🚀 **Project Phases**

<details>
<summary><b>Phase 0 – Local Setup</b></summary>

1. Provision an Ubuntu 22.04 EC2 instance.  
2. Install Docker, clone the repository, and build the container:
   ```bash
   git clone https://github.com/Dzennieva/amazon_clone_docker_GitOps.git
   docker build -t amazon:1 .
   docker run -d -p 8081:3000 amazon:1
   ```
3. Test locally via `http://<EC2-IP>:8081`.
</details>

---

<details>
<summary><b>Phase 1 – Infrastructure Provisioning with Terraform</b></summary>
  
```bash
  git clone https://github.com/Dzennieva/terraform_VPC_EKS.git
```

```bash
terraform init
terraform apply
aws eks --region <region> update-kubeconfig --name <cluster-name>
kubectl get nodes
```
Terraform provisions:
- VPC (public/private subnets, NAT, IGW)
- EKS cluster (control plane, node groups)
</details>

---

<details>
<summary><b>Phase 2 – Security Scanning</b></summary>

### 🔸 SonarQube
```bash
docker run -d --name sonar -p 9000:9000 sonarqube:lts-community
```
Access: `http://<EC2-IP>:9000` (admin/admin)

### 🔸 Trivy
```bash
sudo apt install wget apt-transport-https gnupg lsb-release -y
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/trivy.list
sudo apt update && sudo apt install trivy -y
trivy image amazon:1
```
</details>

---

<details>
<summary><b>Phase 3 – Continuous Integration with Jenkins</b></summary>

**Install Jenkins**
```bash
sudo apt install fontconfig openjdk-21-jre -y
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
 /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update
sudo apt install jenkins -y
sudo systemctl enable jenkins
sudo systemctl start jenkins
sudo systemctl status jenkins

```
**Configure Jenkins**
- Install Plugins: Docker, Pipeline, SonarQube Scanner  
- Add credentials for DockerHub and GitHub  
- Create a Pipeline job linked to your repo

**Webhook Setup**
- Jenkins → Build Triggers → check “GitHub hook trigger for GITScm polling”  
- GitHub → Settings → Webhooks → Add:  
  Payload URL: `http://<jenkins-ip>:8080/github-webhook/`  
  Content type: `application/json`  
- Push commit → Jenkins auto-builds & pushes to DockerHub
</details>

---

<details>
<summary><b>Phase 4 – Continuous Delivery with ArgoCD</b></summary>

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl port-forward svc/argocd-server -n argocd 8085:443
```
- Login using admin credentials  
- Add GitOps repo → Create Application → Enable Auto-Sync  
- ArgoCD syncs manifests to EKS automatically
</details>

---

<details>
<summary><b>Phase 5 – Application Exposure via ALB + Route 53 + ACM</b></summary>

### Step 1 – Deploy with ALB Ingress Controller (HTTP)
```bash
eksctl utils associate-iam-oidc-provider --region <region> --cluster <cluster> --approve
curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json
aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam-policy.json
```
Install via Helm and deploy HTTP ingress.
```bash
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \            
  -n kube-system \
  --set clusterName=<your-cluster-name> \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=<region> \
  --set vpcId=<your-vpc-id>
```

### Step 2 – Configure Route 53 (HTTP Access)
- Register or use existing domain  
- Create hosted zone → Add **A record (Alias)** → ALB DNS  
- Verify: `nslookup yourdomain.com`  
- Access `http://yourdomain.com`

### Step 3 – Secure with ACM (HTTPS)
- Request public certificate (DNS validation) in AWS ACM  
- Add annotation in ingress:
```yaml
alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:<region>:<account>:certificate/<id>
alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80,"HTTPS":443}]'
alb.ingress.kubernetes.io/ssl-redirect: '443'
```
Apply and access via `https://yourdomain.com`.
</details>

---

<details>
<summary><b>Phase 6 – Monitoring & Logging</b></summary>

### Prometheus
```bash
kubectl create ns prometheus

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

helm install my-prometheus prometheus-community/prometheus -n prometheus

kubectl port-forward -n prometheus deploy/my-prometheus-server 9090
```

### Grafana
```bash
kubectl create ns grafana

helm repo add grafana https://grafana.github.io/helm-charts

helm install my-grafana grafana/grafana -n grafana

kubectl port-forward -n grafana deploy/my-grafana 3000:80
```
</details>

---

## ✅ **Verification Summary**
| Step | Command / Check | Expected Result |
|------|------------------|-----------------|
| ALB Ingress (HTTP) | `kubectl get ingress` | ALB DNS accessible via HTTP |
| Route 53 Domain | `nslookup yourdomain.com` | Domain resolves to ALB DNS |
| ACM Certificate | Check ACM Console | Certificate status = Issued |
| HTTPS Access | Visit `https://yourdomain.com` | Secure lock visible |
| Monitoring | View Grafana Dashboard | Metrics displayed successfully |

---

## 🧠 **Technologies Used**
**AWS EKS | Terraform | Jenkins | ArgoCD | Docker | ALB | Route 53 | ACM | Prometheus | Grafana | SonarQube | Trivy**

---

## 🏁 **Outcome**
A fully automated, production-grade **DevOps pipeline** capable of provisioning infrastructure, securing workloads, deploying applications continuously, and monitoring performance, all using open-source and AWS-native tools.

---
