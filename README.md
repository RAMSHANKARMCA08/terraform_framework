# Terraform AWS Framework

Organization-level Terraform framework for reusable AWS infrastructure and
application deployments. Production applications use one shared CloudFront
distribution with path-based routing.

## Repository structure

```text
applications/instant-app/prod/     Application Terraform root and values
applications/myk8sapp/prod/        EKS application Terraform root and values
applications/shared-routing/prod/  Shared CloudFront and public DNS root
cloud/aws/modules/                 Reusable AWS Terraform modules
config/github/sample.env           GitHub Variables and Secrets reference
config/terraform/state-management.json
                                   Common backend configuration
environments/                      Shared platform environment roots
scripts/                           Backend, plan-report, drift, and email tools
.github/workflows/                 Manual CI/CD workflows
```

## Production routing and applications

The public production hostname is `ramdevops.site`. CloudFront removes the
application prefix and forwards the request to an application-owned origin.

| URL | Origin behavior |
| --- | --- |
| `https://ramdevops.site/instant-app` | Mumbai normally; Sydney after Mumbai target failure |
| `https://ramdevops.site/myk8sapp` | Mumbai EKS public NodePort worker |

The root URL redirects to `/instant-app`. Non-production environments follow
`https://<environment>.ramdevops.site/<application>`.

Deploy in this order: `instant-app/prod`, `myk8sapp/prod`, then
`shared-routing/prod`. Destroy in reverse order. The workflow discovers
`shared-routing` as a normal application name, but its state owns shared ingress
rather than an application workload.

### instant-app

Mumbai (`ap-south-1`) is PRIMARY and Sydney (`ap-southeast-2`) is SECONDARY.
Each region contains a two-AZ VPC, public ALB, private Amazon Linux 2023
`t3.micro` EC2 instance, encrypted gp3 volume, security groups, target group,
HTTP-to-HTTPS redirect, and regional ACM certificate. EC2 instances are attached
directly to their target groups; Auto Scaling is disabled for `instant-app`.

Its failover origin is `origin-instant-app.ramdevops.site`; regional diagnostic
hostnames remain available for troubleshooting.

### myk8sapp

One public EKS worker in Mumbai runs the test workload. The origin hostname
`origin-myk8sapp.ramdevops.site` maps to the worker, and CloudFront connects to
NodePort `30080`. There is no application load balancer for this test stack.

Apache `httpd` displays the application greeting, EC2 hostname, and server
location. Taggable resources include `env = prod` and
`projectname = instant-app`.

## Reusable modules

The instant application root calls `multi-region-alb-app`, which composes the reusable
`vpc`, `regional-alb-app`, `alb`, and `security-groups` modules. Other available
modules include `cloudfront-path-router`, EKS, ECR, IAM, VPC endpoints, Route 53
zones, WAF, and supporting Kubernetes controllers.

## GitHub Actions

All workflows are manually triggered; automatic schedules and PR triggers are
disabled.

### Application Terraform Operations

Select `application_name` (default `instant-app`), `env` (default `prod`), and
one manually triggered `run` operation:

- `plan`: create a non-apply plan and publish a redacted Markdown change table.
- `deploy`: create a saved plan and apply it with automatic approval.
- `drift`: run a refresh-only plan, publish a drift report, and fail when drift exists.
- `delete`: create and publish a destroy plan, apply it with automatic approval,
  and verify that the selected state is empty.

### Application Delete

Select `appname` and `environment`, then type `DELETE`. The workflow publishes a
human-readable destroy table, applies the saved destroy plan automatically, and
verifies that the selected state is empty. It does not destroy the shared Route
53 hosted zone, state storage, or externally imported EC2 key pair.

### Application Terraform Drift

Takes no inputs. It discovers every `applications/<application>/<environment>`
Terraform root, checks them in parallel, aggregates drift details, and sends one
HTML table email only when actual drift exists. Clean checks send no email.

### Terraform Security

Runs TFLint and Terrascan manually. Its previous push and pull-request triggers
remain commented for future re-enablement.

### Application Cost Report

Queries the state-owned monthly AWS Budget and Cost Explorer for the selected
application/environment. It groups month-to-date unblended cost by AWS service
and publishes the budget limit, actual spend, and forecast in the job summary.

## State management

Common settings are defined in
[`config/terraform/state-management.json`](config/terraform/state-management.json).
PostgreSQL is the current default; S3 remains available. Application/environment
identity stays isolated through PostgreSQL schema names or S3 keys.

Generic GitHub settings are used:

```text
TF_STATE_CONNECTION   PostgreSQL connection string secret
TF_STATE_STORAGE      S3 bucket variable when the S3 backend is selected
```

Changing an existing backend requires a controlled `terraform init
-migrate-state`. Pipelines never migrate state automatically.

## GitHub configuration

Use [`config/github/sample.env`](config/github/sample.env) as the reference.
AWS credentials come from the self-hosted runner's IAM role or local AWS
credential chain. The `ramkey2026` EC2 key pair must already exist in each AWS
region used by the application; private keys are never stored in GitHub.

SMTP variables and secrets are required only for drift email. The Infracost key
is required only for cost-estimation workflows that use it.

## Route 53 and GoDaddy

Terraform looks up the existing public `ramdevops.site` Route 53 hosted zone.
Application states create origin records; `shared-routing/prod` creates the apex
CloudFront A/AAAA aliases and its ACM-validation record. At GoDaddy, configure the
domain to use the four authoritative Route 53 nameservers. Coordinate any DNSSEC
DS records before changing delegation.

## Production recommendations

- Activate `projectname` and `env` as user-defined cost allocation tags in AWS
  Billing; tag-filtered Cost Explorer and Budget data is unavailable until then.
- Enable Cost Explorer in the payer/management account and grant the workflow
  `ce:GetCostAndUsage`, `budgets:ViewBudget`, and `sts:GetCallerIdentity`.
- Review the default `instant-app-prod-monthly` budget limit of USD 50.
- Prefer GitHub OIDC with short-lived AWS credentials over long-lived access keys.
- Add AWS Budget email/SNS notifications for actual and forecast thresholds.
- Consider Session Manager instead of SSH and remove the EC2 key pair requirement.
- Add VPC Flow Logs, ALB access logs, CloudWatch alarms, and centralized retention.
- Use at least two EC2 targets for production availability; the requested single
  direct EC2 instance makes each region individually single-instance.
- Add AWS WAF to the public ALBs and restrict administrative network access.
- Run periodic restore, Route 53 failover, and deletion tests in a non-production account.

## Deletion ownership

Application Delete destroys every managed resource recorded in the selected
application/environment Terraform state, including both EC2 instances, volumes,
ALBs, target groups, listeners, security groups, VPC networking, NAT gateways,
Elastic IPs, ACM certificates, origin DNS records, and the AWS Budget. It
then fails if anything remains in Terraform state.

It intentionally does not delete the shared Route 53 hosted zone, PostgreSQL/S3
state infrastructure, GoDaddy domain/delegation, GitHub settings, or the
externally managed `ramkey2026` key pair. The shared CloudFront distribution is
owned by `shared-routing/prod`; destroy it before destroying either origin
application. AWS billing history remains visible after deletion. Resources
created manually or removed from Terraform state are outside the deletion
guarantee.

For the S3 backend, state keys use `<application>/<environment>.tfstate`. The
`instant-app/prod` state is therefore stored as
`s3://<TF_STATE_STORAGE>/instant-app/prod.tfstate`. Changing an existing key is a
state migration, not a fresh deployment; migrate or copy the existing object
before planning against the new key.

## Local validation

Generate the backend declaration before running Terraform:

```bash
python3 scripts/configure_state_backend.py \
  --application instant-app \
  --environment prod \
  --output applications/instant-app/prod/backend.generated.tf

terraform fmt -recursive
terraform -chdir=applications/instant-app/prod init
terraform -chdir=applications/instant-app/prod validate
terraform -chdir=applications/instant-app/prod plan -var-file=terraform.tfvars

terraform -chdir=applications/myk8sapp/prod init
terraform -chdir=applications/myk8sapp/prod validate
terraform -chdir=applications/myk8sapp/prod plan -var-file=terraform.tfvars

terraform -chdir=applications/shared-routing/prod init
terraform -chdir=applications/shared-routing/prod validate
terraform -chdir=applications/shared-routing/prod plan -var-file=terraform.tfvars
```

For PostgreSQL, export `PG_CONN_STR`. For S3, supply the configured bucket using
`terraform init -backend-config="bucket=<state-storage>"`.
