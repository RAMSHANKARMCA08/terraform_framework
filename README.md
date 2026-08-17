# Terraform AWS Framework

Organization-level Terraform framework for reusable AWS infrastructure and
application deployments. The current application is `instant-app` in `prod`,
deployed to Mumbai and Sydney with Route 53 failover.

## Repository structure

```text
applications/instant-app/prod/     Application Terraform root and values
cloud/aws/modules/                 Reusable AWS Terraform modules
config/github/sample.env           GitHub Variables and Secrets reference
config/terraform/state-management.json
                                   Common backend configuration
environments/                      Shared platform environment roots
scripts/                           Backend, plan-report, drift, and email tools
.github/workflows/                 Manual CI/CD workflows
```

## instant-app architecture

Mumbai (`ap-south-1`) is PRIMARY and Sydney (`ap-southeast-2`) is SECONDARY.
Each region contains a two-AZ VPC, public ALB, private Amazon Linux 2023
`t3.micro` EC2 instance, encrypted gp3 volume, security groups, target group,
HTTP-to-HTTPS redirect, and regional ACM certificate. EC2 instances are attached
directly to their target groups; Auto Scaling is disabled for `instant-app`.

| URL | Behavior |
| --- | --- |
| `https://instant-app.ramdevops.site` | Mumbai normally; Sydney after Mumbai target failure |
| `https://mumbai-instant-app.ramdevops.site` | Mumbai ALB only |
| `https://sydney-instant-app.ramdevops.site` | Sydney ALB only |

Apache `httpd` displays the application greeting, EC2 hostname, and server
location. Taggable resources include `env = prod` and
`projectname = instant-app`.

## Reusable modules

The application root calls `multi-region-alb-app`, which composes the reusable
`vpc`, `regional-alb-app`, `alb`, and `security-groups` modules. Other available
modules support EKS, ECR, IAM, VPC endpoints, Route 53 zones, WAF, and supporting
Kubernetes controllers.

## GitHub Actions

All workflows are manually triggered; automatic schedules and PR triggers are
disabled.

### Application Deployment

Select `appname`, `environment`, and one operation:

- `PLAN`: create a non-apply plan and publish a redacted Markdown change table.
- `DEPLOY`: create a saved plan and apply it with automatic approval.
- `CHECK_DRIFT`: run a refresh-only plan and fail when drift exists.

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
Required AWS secrets are `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`;
`AWS_SESSION_TOKEN` is optional for temporary credentials. `AWS_EC2_KEYPAIR`
contains the OpenSSH public key used to import regional `ramkey2026` key pairs.
Never store the private PEM in GitHub or Terraform state.

SMTP variables and secrets are required only for drift email. The Infracost key
is required only for cost-estimation workflows that use it.

## Route 53 and GoDaddy

Terraform looks up the existing public `ramdevops.site` Route 53 hosted zone and
creates only application and ACM-validation records. At GoDaddy, configure the
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
Elastic IPs, ACM certificates, application DNS records, and the AWS Budget. It
then fails if anything remains in Terraform state.

It intentionally does not delete the shared Route 53 hosted zone, PostgreSQL/S3
state infrastructure, GoDaddy domain/delegation, GitHub settings, or the
workflow-imported `ramkey2026` key pair. AWS billing history also remains visible
after deletion. Resources created manually or removed from Terraform state are
outside the deletion guarantee.

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
```

For PostgreSQL, export `PG_CONN_STR`. For S3, supply the configured bucket using
`terraform init -backend-config="bucket=<state-storage>"`.
