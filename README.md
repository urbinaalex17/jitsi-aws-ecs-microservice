# jitsi-aws-ecs-microservice
Deploy Jitsi Meet in Amazon Elastic Container Cluster as microservice with Terraform

## Prerequisites

| Component | Description | Version |
| --- | --- | --- |
| Terraform | Provision AWS Resources | => 0.13 |

### Configure variables

Take a look at [vars.tf](vars.tf) and [terraform.tfvars](terraform.tfvars)

## Getting Started

AWS credentials for authentication: 

```bash
export AWS_SECRET_ACCESS_KEY=<value>
export AWS_ACCESS_KEY_ID=<value>
```
Download providers: 

```bash
terraform init
```

### Deploy the infrastructure

```bash
terraform plan
```

```bash
terraform apply
```

### Destroy the infrastructure

```bash
terraform destroy
```
