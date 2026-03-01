# GCP Cloud Service to Create a VM to Leverage Auto Scaling and Security

##  Project Objective
The objective of this project is to create a secure, self-healing, and auto-scaling cloud architecture. The deployment relies on four core design pillars:
1. **Elasticity**: Expanding and contracting infrastructure dynamically based on real-time CPU utilization.
2. **Security-by-Design**: A Zero-Trust model implemented via granular IAM roles enforcing the principle of least privilege.
3. **Network Security (Firewalls)**: Strict ingress and egress rules to protect backend infrastructure from unverified external traffic.
4. **High Availability (HA)**: Using a Global External Application Load Balancer to abstract instance variations from the end user and ensure non-stop uptime.


##  Project Structure
├── README.md                     
├── startup-script.sh               
├── stress-test.sh                 
├── autoscaling-policy.yaml        
└── reports/
    ├── M25CSE012_deployment_and_configuration.pdf  
    └── M25CSE012_Assignment2_report.pdf             
## Architectural Diagram
<img width="925" height="482" alt="image" src="https://github.com/user-attachments/assets/2f0614cf-9051-451a-ac42-7d50cfae27d6" />



### 1. Instance Template
Infrastructure as Code (IaC) principles were applied to ensure reproducibility and prevent configuration drift. 
* **Template Name**: `eshani-assignmnet2-webserver-template`.
* A bootstrap `startup-script.sh` is embedded within the template. It installs Apache and a stress-testing tool, then registers the VM hostname on a landing page so scaled replicas can be visually tracked.

### 2. Managed Instance Group (MIG)
* **Group Name**: `eshani-assignment-autoscaling-group`.
* **Self-Healing**: If an instance fails its health check, the MIG automatically deletes and reconstructs it.
* **Auto-Scaling Logic**: The MIG scales instances between **1 (min)** and **4 (max)** across multiple availability zones based on a **60% CPU utilization** threshold with a 60-second cooldown period.

### 3. Traffic Management & Load Balancing
* **Global Load Balancer**: Single point of entry (`eshani-webserver-loadbalancer`) which proxies traffic to backend VMs.
* **Health Checks**: (`eshani-web-server-health-check`) Monitor Apache instances (Port 80) every 5 seconds. A `200 OK` response is required for the instance to remain active. Unresponsive instances are safely removed from the routing pool.

### 4. Security & Hardening
* **IAM Least Privilege**: Replaced default roles with a custom role (`Eshani Custom VM Viewer`). Granted specific privileges like `compute.instances.get` and `compute.instances.list` to limit the threat surface (e.g., auditors cannot delete firewalls).
* **VPC Firewalls**: 
    * `eshani-deny-unsecure-ingress` blocks all unauthorized entry streams.
    * `allow-health-checks` specifically whitelists Google’s internal health-checking ranges (`130.211.0.0/22`, `35.191.0.0/16`) to communicate via TCP port 80.
### 5.Firewall Rules
[cite_start]The following table outlines the critical VPC firewall rules configured to harden the network and manage traffic securely:

| Rule Name | Action | Protocol / Port | Source IP Ranges | Purpose and Logic |
| :--- | :--- | :--- | :--- | :--- |
| **allow-lb-traffic** / **allow-health-checks** | Allow | TCP: 80 | `130.211.0.0/22`, `35.191.0.0/16` | [cite_start]Allows the Global Load Balancer to communicate with backend instances, forward user requests, and perform continuous health checks[cite: 4, 67]. |
| **allow-iap-ssh** | Allow | TCP: 22 | `35.235.240.0/20` | [cite_start]Enables secure SSH access via Identity Aware Proxy (IAP) to safely run the stress test without exposing a public IP[cite: 4]. |
| **deny-direct-public** | Deny | TCP: 80 | `0.0.0.0/0` | [cite_start]Prevents the public from bypassing the Load Balancer to hit the VM directly[cite: 4]. |
| **eshani-deny-unsecure-ingress** / **deny-all-ingress** | Deny | All unsecure | `0.0.0.0/0` | [cite_start]A Priority 900 rule that blocks all unauthorized entry streams and traffic on unsecure ports[cite: 4, 66]. |

---

### 6. Location Setup Guidelines
When deploying this architecture, adhere to the following location and distribution strategies:
* **Region Strategy:** Resources should be deployed in the `us-central1` region. 
* **Zone Distribution:** The Managed Instance Group (MIG) should distribute instances across **Multiple Zones** within `us-central1`. This multi-zone deployment is a crucial setup step to protect the application and ensure high availability in case a single Google data center experiences an outage.

---

## Code to Setup

### 1. Startup Script (`startup-script.sh`)
Embed this script in your Instance Template (`eshani-assignmnet2-webserver-template`). [cite_start]It automates the environment setup for every new VM created by the Managed Instance Group[cite: 1, 56]:
```bash
#!/bin/bash
# Update and install required packages
apt-get update
apt-get install -y apache2 stress

# Create a basic landing page identifying the host
echo "<h1>Scalable Web Server: \$(hostname)</h1>" > /var/www/html/index.html

# Ensure Apache starts on boot
systemctl enable apache2
systemctl start apache2
```

## Performance Validation (Stress Testing)
To demonstrate the system's elasticity, a forced CPU load test was performed:
1. SSH into the primary VM (`eshani-assignment-autoscaling-group-qcn3`).
2. Execute the `stress-test.sh` command to push CPU load to 100%.
3. **Result:** The Autoscaler correctly identified the breach of the 60% threshold.
4. New instances were automatically provisioned and reported green (healthy) within 90 seconds. 
5. The Load Balancer effectively routed ongoing requests across the new backend capacity without interrupting user service. 



##  Conclusion


This project successfully demonstrates a secure and highly available cloud architecture. By leveraging an Instance Template and a Managed Instance Group (MIG), the deployment of identically configured VMs was fully automated. Security was strictly enforced using restrictive VPC firewall policies and custom IAM roles, while a Global Load Balancer ensured traffic was exclusively routed to healthy backends. Finally, the system's elasticity was proven through a stress test, which successfully triggered the Autoscaler to dynamically expand the infrastructure from 1 to 4 instances in response to simulated heavy CPU load.
