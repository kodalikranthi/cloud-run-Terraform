# Internal Load Balancer with HTTPS for Cloud Run Services

This configuration provides an internal load balancer with HTTPS support that can expose multiple Cloud Run services through a single forwarding rule using Network Endpoint Groups (NEGs).

## Features

- **Single Forwarding Rule**: One forwarding rule that supports multiple Cloud Run services
- **HTTPS Support**: SSL certificate from Secret Manager with multiple SANs
- **Path-based Routing**: Route traffic to different services based on URL paths
- **Internal Load Balancer**: Accessible only within your VPC network
- **NEG Dependencies**: NEGs properly depend on Cloud Run services

## Configuration

### 1. SSL Certificate Setup

**Manually create the SSL certificate secret in Secret Manager** (outside of Terraform):

```bash
# Create the secret manually
gcloud secrets create ssl-certificate --data-file=your-certificate.pem
```

The certificate format should be:
```
-----BEGIN CERTIFICATE-----
YOUR_CERTIFICATE_CONTENT
-----END CERTIFICATE-----
-----BEGIN PRIVATE KEY-----
YOUR_PRIVATE_KEY_CONTENT
-----END PRIVATE KEY-----
```

**Note**: The SSL certificate secret must be created manually outside of Terraform. Terraform will only reference this existing secret.

### 2. Static IP Configuration

Configure static IP reservation for the load balancer:

```hcl
# Internal Load Balancer Configuration
internal_load_balancer = {
  name                    = "internal-lb"
  create_static_ip        = true          # Set to true to reserve a static IP
  static_ip_address       = "10.0.0.100"  # Optional: specify the static IP address
  ssl_certificate_secret  = "ssl-certificate"  # Manually created secret
  services = {
    "app" = {
      service_name = "my-app"
      path         = "/app/*"
    }
    "api" = {
      service_name = "my-api"
      path         = "/api/*"
    }
    "admin" = {
      service_name = "my-admin"
      path         = "/admin/*"
    }
  }
}
```

**Static IP Options:**
- `create_static_ip = true`: Terraform will reserve a static IP from the subnet
- `static_ip_address = "10.0.0.100"`: Specify the exact IP address to reserve
- `create_static_ip = false`: Use dynamic IP assignment (default)

### 3. Cloud Run Services

Ensure your Cloud Run services are configured to match the service names in the load balancer configuration:

```hcl
cloud_run_services = {
  "app" = {
    name         = "my-app"      # This name must match service_name in load balancer
    image_name   = "app"
    image_tag    = "latest"
    # ... other configuration
  }
  "api" = {
    name         = "my-api"      # This name must match service_name in load balancer
    image_name   = "api"
    image_tag    = "v1.0"
    # ... other configuration
  }
  "admin" = {
    name         = "my-admin"    # This name must match service_name in load balancer
    image_name   = "admin"
    image_tag    = "latest"
    # ... other configuration
  }
}
```

**Important**: The keys in `internal_load_balancer.services` must match the keys in `cloud_run_services` for the NEG alignment to work correctly.

## How It Works

1. **NEGs**: Each Cloud Run service gets a Network Endpoint Group (NEG) that depends on the Cloud Run service
2. **Backend Services**: Backend services are created only for services defined in `internal_load_balancer.services`
3. **URL Map**: Path-based routing directs traffic to the appropriate backend service
4. **SSL Certificate**: Retrieved from Secret Manager and used for HTTPS termination
5. **Forwarding Rule**: Single forwarding rule on port 443 for all services

**Key Improvement**: Backend services are now created dynamically based on the `internal_load_balancer.services` configuration, ensuring only the services you want to expose through the load balancer get backend services.

**NEG Alignment**: The system uses matching keys between `internal_load_balancer.services` and `cloud_run_services` to directly reference the correct NEGs, ensuring proper connectivity.

**Standard Configuration**: All backend services use the standard Cloud Run configuration:
- **Protocol**: `HTTP` (standard for Cloud Run)
- **Port Name**: `http` (standard for Cloud Run)

## Routing

The load balancer uses path-based routing:

- `https://internal-lb-ip/app/*` → Cloud Run service "my-app"
- `https://internal-lb-ip/api/*` → Cloud Run service "my-api"
- `https://internal-lb-ip/admin/*` → Cloud Run service "my-admin"

## Outputs

After deployment, you'll get these outputs:

- `internal_load_balancer_ip`: The IP address of the load balancer
- `internal_load_balancer_static_ip`: Static IP details (if `create_static_ip = true`)
- `internal_load_balancer_forwarding_rule`: Details about the forwarding rule
- `internal_load_balancer_url_map`: URL map configuration with service routing
- `internal_load_balancer_backend_services`: Backend services created for load balancer

## Dependencies

The configuration ensures proper dependencies:

- NEGs depend on Cloud Run services
- Backend services depend on Cloud Run services
- Forwarding rule depends on backend services and Cloud Run services

## Security

- Internal load balancer is only accessible within your VPC
- SSL certificate is stored securely in Secret Manager
- All traffic is encrypted with HTTPS

## Example Usage

```bash
# Deploy the infrastructure
terraform init
terraform plan
terraform apply

# Access your services
curl -k https://10.0.0.100/app/health
curl -k https://10.0.0.100/api/v1/status
curl -k https://10.0.0.100/admin/dashboard
```

## Troubleshooting

1. **SSL Certificate Issues**: Ensure the certificate is properly formatted in Secret Manager
2. **Service Not Found**: Check that the service names in `internal_load_balancer.services` match the Cloud Run service names
3. **Path Routing**: Verify that the paths are correctly configured and don't overlap
4. **Network Access**: Ensure the load balancer is accessible from your intended clients within the VPC