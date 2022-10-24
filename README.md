## Super Simple Terraform

Using `aws` to configure IAM user access key and secrets. Don't use the root user, it's better to create a user group with set policies or an IAM user and define the restrictive policies. This repo will aim to provision a sane Terraform infra for the `PERN` stack (PostgreSQL, Express, React, Node).

The stack should ideally reach the following state:

1. Provision the infrastructure using Terraform
2. Run TF in CI/CD
3. Use Docker to containerise the React and Express apps
4. Use Ansible or Kubernetes to orchestrate the deployment step in Github Actions or alternative CD

The goal is to become cloud agnostic while automating the great majority of DevOps on a solid stack to focus on feature delivery + business dev. That is - having the ability to quickly `terraform apply` anywhere and `terraform destroy` using simple commands. The default provider is currently `aws`.

## AWS

Terraform should provide the following for most full stack apps:

1. RDS
2. EC2
3. S3
4. Route53

Horizontal scaling will be achieved by scaling up the number of instances with a load balancer.

`note`: might add Redis for caching things like JWT tokens

## Usage

Terraform will init in the repo on:

```bash
terraform init
```

Check the TF plan before applying:

```bash
terraform plan
```

Apply the proposed changes:

```bash
terraform apply
```

To destroy all the instances:

```bash
terraform destroy
```

The `ami` used in `main.tf` is an ID to an `amd64` variant of Ubuntu 20.04 LTS in `eu-west-1`.

## TF State Management

State is currently handled (was migrated from local backend) in Terraform Cloud with local execution enabled due to shared credentials in `~/.aws`. This will be soon migrated yet again to remote execution using Github Actions.
