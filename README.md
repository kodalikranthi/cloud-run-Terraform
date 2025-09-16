# GCP Cloud Run with Internal Load Balancer - Terraform

This Terraform configuration provisions a complete Google Cloud Platform infrastructure for a Cloud Run application with internal load balancing, secret management, and encryption.

## Project Structure

```
cloud-run-Terraform/
├── iaac/                          # Infrastructure as Code files
│   ├── provider.tf               # Provider configuration
│   ├── locals.tf                 # Local values and common variables
│   ├── network.tf                # VPC, subnets, and networking
│   ├── artifact-registry.tf      # Google Artifact Registry
│   ├── kms.tf                    # Cloud KMS key ring and keys
│   ├── secret-manager.tf         # Secret Manager with KMS encryption
│   ├── cloud-run.tf              # Cloud Run service and NEG
│   ├── load-balancer.tf          # Internal load balancer and SSL
│   ├── iam.tf                    # IAM roles and permissions
│   └── outputs.tf                # Output values
├── tfvars/                       # Variables and configuration
│   ├── variables.tf              # Variable definitions
│   └── terraform.tfvars.example  # Example configuration
├── .gitignore                    # Git ignore file
└── README.md                     # This file
```

## Architecture Overview

The infrastructure includes:

- **Cloud Run Service**: Containerized application with internal access only
- **Google Artifact Registry**: Private container image repository
- **Secret Manager**: Encrypted secrets with KMS integration
- **Cloud KMS**: Key management for encrypting secrets
- **Internal Load Balancer**: HTTPS load balancer with SSL certificate
- **VPC Network**: Private network for internal communication
- **IAM**: Least privilege access controls

## Variables Reference

| S.No | Variable | Description | Required | Default Value | Example |
|------|----------|-------------|----------|---------------|---------|
| 1 | `project_id` | The GCP project ID | Yes | - | `"my-gcp-project"` |
| 2 | `region` | The GCP region | No | `"australia-southeast2"` | `"us-central1"` |
| 3 | `environment` | Environment name (dev, staging, prod) | No | `"dev"` | `"production"` |
| 4 | `cloud_run_services` | Map of Cloud Run services to create | No | See below | See Cloud Run Services section |
| 5 | `secrets` | Map of secrets to create in Secret Manager | No | See below | `{"API_KEY": "secret123"}` |
| 6 | `existing_vpc_network` | Name of existing VPC network | No | `"default"` | `"my-vpc"` |
| 7 | `existing_vpc_subnet` | Name of existing VPC subnet | No | `"default"` | `"my-subnet"` |
| 8 | `vpc_access_connector_name` | Name of existing VPC access connector | No | `"vpc-connector"` | `"my-connector"` |
| 9 | `vpc_access_connector_region` | Region of existing VPC access connector | No | `"australia-southeast2"` | `"us-central1"` |
| 10 | `load_balancer_network` | Network name for load balancer | No | `"default"` | `"lb-network"` |
| 11 | `load_balancer_subnet` | Subnet name for load balancer | No | `"default"` | `"lb-subnet"` |
| 12 | `load_balancer_ip_address` | IP address for load balancer (optional) | No | `null` | `"10.0.0.100"` |
| 13 | `ssl_certificates` | Map of SSL certificates to create | No | See below | See SSL Certificates section |
| 14 | `spanner_instances` | Map of Spanner instances for database access | No | `{}` | See Spanner section |
| 15 | `artifact_registries` | Map of Artifact Registry repositories to create | No | See below | See Artifact Registry section |
| 16 | `kms_key_rings` | Map of KMS key rings to create | No | See below | See KMS section |
| 17 | `kms_keys` | Map of KMS keys to create | No | See below | See KMS section |

### Cloud Run Services Configuration

| Field | Description | Required | Default | Example |
|-------|-------------|----------|---------|---------|
| `name` | Cloud Run service name | Yes | - | `"my-app"` |
| `image_name` | Container image name | Yes | - | `"app"` |
| `image_tag` | Container image tag | Yes | - | `"latest"` |
| `cpu_limit` | CPU limit for the service | Yes | - | `"1"` |
| `memory_limit` | Memory limit for the service | Yes | - | `"512Mi"` |
| `min_instances` | Minimum number of instances | Yes | - | `1` |
| `max_instances` | Maximum number of instances | Yes | - | `10` |
| `environment_vars` | Regular environment variables | No | `{}` | `{"PORT": "8080"}` |
| `secret_names` | List of secret names from Secret Manager | No | `[]` | `["API_KEY", "DB_URL"]` |

### SSL Certificates Configuration

| Field | Description | Required | Default | Example |
|-------|-------------|----------|---------|---------|
| `domains` | List of domains for the certificate | Yes | - | `["example.com", "www.example.com"]` |

### Spanner Configuration

| Field | Description | Required | Default | Example |
|-------|-------------|----------|---------|---------|
| `instance_id` | Spanner instance ID | Yes | - | `"my-spanner-instance"` |
| `database_id` | Spanner database ID | Yes | - | `"my-database"` |

### Artifact Registry Configuration

| Field | Description | Required | Default | Example |
|-------|-------------|----------|---------|---------|
| `repository_id` | Repository ID | Yes | - | `"my-repo"` |
| `description` | Repository description | Yes | - | `"My Docker repository"` |
| `format` | Repository format | Yes | - | `"DOCKER"` |

### KMS Configuration

| Field | Description | Required | Default | Example |
|-------|-------------|----------|---------|---------|
| `location` | Key ring location | Yes | - | `"australia-southeast2"` |
| `key_ring_name` | Key ring name (for keys) | Yes | - | `"main"` |
| `rotation_period` | Key rotation period | Yes | - | `"7776000s"` (90 days) |

## Prerequisites

1. **Google Cloud SDK** installed and configured
2. **Terraform** >= 1.0 installed
3. **GCP Project** with billing enabled
4. **Domain name** for SSL certificate (must be verified in GCP)
5. **Container image** built and ready for deployment

## Setup Instructions

### 1. Clone and Configure

```bash
# Clone the repository
git clone <your-repo-url>
cd cloud-run-Terraform

# Copy the example variables file
cp tfvars/terraform.tfvars.example tfvars/terraform.tfvars
```

### 2. Update Configuration

Edit `tfvars/terraform.tfvars` with your specific values:

```hcl
# Required
project_id   = "your-gcp-project-id"
domain_name  = "your-domain.com"

# Optional - customize as needed
project_name = "my-app"
region       = "us-central1"
environment  = "dev"
```

### 3. Authenticate with GCP

```bash
# Authenticate with Google Cloud
gcloud auth login
gcloud auth application-default login

# Set the project
gcloud config set project your-gcp-project-id
```

### 4. Initialize and Deploy

```bash
# Navigate to the iaac directory
cd iaac

# Initialize Terraform
terraform init

# Review the plan
terraform plan -var-file=../tfvars/terraform.tfvars

# Apply the configuration
terraform apply -var-file=../tfvars/terraform.tfvars
```

### 5. Build and Push Container Image

```bash
# Configure Docker for Artifact Registry
gcloud auth configure-docker us-central1-docker.pkg.dev

# Build your container image
docker build -t us-central1-docker.pkg.dev/your-project-id/cloud-run-app-repo/app:latest .

# Push to Artifact Registry
docker push us-central1-docker.pkg.dev/your-project-id/cloud-run-app-repo/app:latest
```

## File Descriptions

### iaac/ Directory

- **`provider.tf`**: Google Cloud provider configuration and data sources
- **`locals.tf`**: Common local values for consistent naming and configuration
- **`network.tf`**: VPC network, subnets, and internal IP addresses
- **`artifact-registry.tf`**: Google Artifact Registry repository for container images
- **`kms.tf`**: Cloud KMS key ring and encryption keys
- **`secret-manager.tf`**: Secret Manager secrets with KMS encryption
- **`cloud-run.tf`**: Cloud Run service and serverless network endpoint group
- **`load-balancer.tf`**: Internal load balancer, SSL certificate, and forwarding rules
- **`iam.tf`**: IAM roles, service accounts, and permissions
- **`outputs.tf`**: Output values for reference

### tfvars/ Directory

- **`variables.tf`**: Variable definitions with types and descriptions
- **`terraform.tfvars.example`**: Example configuration file

## IAM Roles Used

This configuration uses the following IAM roles following the least privilege principle:

### Service Accounts

1. **Cloud Run Service Account** (`cloud-run-app-cloudrun@project.iam.gserviceaccount.com`)
   - `roles/secretmanager.secretAccessor` - Access to secrets
   - `roles/cloudkms.cryptoKeyDecrypter` - Decrypt secrets
   - `roles/artifactregistry.reader` - Pull container images
   - `roles/run.invoker` - Invoke Cloud Run service

2. **Compute Service Agent** (`service-{project-number}@compute-system.iam.gserviceaccount.com`)
   - `roles/compute.serviceAgent` - Manage compute resources
   - `roles/certificatemanager.admin` - Manage SSL certificates
   - `roles/compute.networkAdmin` - Manage network resources

### User Permissions Required

To deploy this infrastructure, your user account needs:

- `roles/owner` or `roles/editor` - Deploy resources
- `roles/iam.serviceAccountAdmin` - Create service accounts
- `roles/iam.serviceAccountKeyAdmin` - Manage service account keys
- `roles/resourcemanager.projectIamAdmin` - Manage IAM policies

## Resource Details

### Cloud Run Service
- **Access**: Internal only (no public URL)
- **Scaling**: 1-10 instances (configurable, optimized for latency-sensitive apps)
- **Resources**: 1 CPU, 512Mi memory (configurable)
- **Environment Variables**: From Secret Manager
- **Network**: Private VPC with egress only to private ranges
- **Cold Start Prevention**: Minimum 1 instance always running

### Secret Manager
- **Encryption**: Customer-managed KMS keys
- **Replication**: Regional
- **Access**: Only Cloud Run service account

### Load Balancer
- **Type**: Internal HTTPS load balancer
- **SSL Certificate**: Google-managed certificate
- **Backend**: Cloud Run service via serverless NEG
- **Access**: Internal VPC only

### KMS
- **Key Ring**: Regional
- **Key Type**: Symmetric encryption
- **Rotation**: 90 days
- **Usage**: Secret Manager encryption

## Latency Optimization for Sensitive Applications

This configuration is optimized for latency-sensitive applications with the following features:

### Cold Start Prevention
- **Minimum Instances**: Set to 1 to ensure at least one instance is always running
- **No Cold Starts**: Eliminates the delay caused by container initialization
- **Consistent Performance**: Predictable response times for your application

### Performance Configuration
```hcl
# Example for latency-sensitive application
cloud_run_services = {
  "api" = {
    name         = "latency-sensitive-api"
    image_name   = "api"
    image_tag    = "latest"
    cpu_limit    = "2"           # Higher CPU for faster processing
    memory_limit = "1Gi"         # More memory for better performance
    min_instances = 1            # Always keep 1 instance running
    max_instances = 20           # Scale up for high traffic
    environment_vars = {
      "ENVIRONMENT" = "production"
      "LOG_LEVEL"   = "warn"     # Reduce logging overhead
    }
    secret_names = ["API_KEY", "DB_URL"]
  }
}
```

### Additional Optimizations
- **CPU Allocation**: Consider increasing CPU limit for faster processing
- **Memory Allocation**: Ensure sufficient memory to avoid swapping
- **Log Level**: Use appropriate log levels to reduce I/O overhead
- **Image Optimization**: Use optimized container images for faster startup

## Deployment and Management

### Deploying Updates

1. **Update container image**:
   ```bash
   # Build and push new image
   docker build -t us-central1-docker.pkg.dev/your-project-id/cloud-run-app-repo/app:v2.0 .
   docker push us-central1-docker.pkg.dev/your-project-id/cloud-run-app-repo/app:v2.0
   
   # Update Terraform variables
   # In tfvars/terraform.tfvars: image_tag = "v2.0"
   
   # Apply changes
   cd iaac
   terraform apply -var-file=../tfvars/terraform.tfvars
   ```

2. **Update secrets**:
   ```bash
   # Update secret values in tfvars/terraform.tfvars
   # Apply changes
   cd iaac
   terraform apply -var-file=../tfvars/terraform.tfvars
   ```

3. **Scale the service**:
   ```bash
   # Update min_instances and max_instances in tfvars/terraform.tfvars
   cd iaac
   terraform apply -var-file=../tfvars/terraform.tfvars
   ```

### Monitoring and Logging

- **Cloud Run Logs**: Available in Cloud Logging
- **Load Balancer Logs**: Enabled with 100% sampling
- **Secret Access Logs**: Available in Cloud Audit Logs

### Security Considerations

1. **Network Security**:
   - Cloud Run service is not publicly accessible
   - Internal load balancer only accessible from VPC
   - Private Google Access enabled

2. **Secret Management**:
   - All secrets encrypted with customer-managed KMS keys
   - Secrets only accessible by Cloud Run service account
   - Automatic key rotation every 90 days

3. **Access Control**:
   - Least privilege IAM roles
   - Service account isolation
   - No public internet access to Cloud Run

## Troubleshooting

### Common Issues

1. **SSL Certificate Not Provisioned**:
   - Ensure domain is verified in Google Search Console
   - Check DNS records point to the load balancer IP
   - Wait up to 60 minutes for certificate provisioning

2. **Container Image Not Found**:
   - Verify image is pushed to Artifact Registry
   - Check image name and tag in tfvars/terraform.tfvars
   - Ensure Cloud Run service account has Artifact Registry access

3. **Secrets Not Accessible**:
   - Verify KMS key permissions
   - Check secret names match environment variables
   - Ensure Cloud Run service account has secret access

### Useful Commands

```bash
# Check Cloud Run service status
gcloud run services describe cloud-run-app --region=us-central1

# View logs
gcloud logging read "resource.type=cloud_run_revision" --limit=50

# Test internal connectivity
gcloud compute ssh instance-name --zone=us-central1-a --command="curl -k https://internal-lb-ip"

# List secrets
gcloud secrets list

# Check IAM permissions
gcloud projects get-iam-policy your-project-id
```

## Cleanup

To destroy all resources:

```bash
cd iaac
terraform destroy -var-file=../tfvars/terraform.tfvars
```

**Warning**: This will permanently delete all resources including secrets and KMS keys. Make sure to backup any important data before running this command.

## Cost Optimization

- **Cloud Run**: Pay only for requests and compute time
- **Load Balancer**: Fixed cost for internal load balancer
- **KMS**: Cost per key and operations
- **Secret Manager**: Cost per secret and access operations
- **Artifact Registry**: Storage cost for container images

## Support

For issues and questions:
1. Check the troubleshooting section above
2. Review GCP documentation for specific services
3. Check Terraform provider documentation
4. Open an issue in the repository