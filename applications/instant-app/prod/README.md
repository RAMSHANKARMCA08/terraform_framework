# instant-app production

This root deploys `instant-app` to Mumbai (`ap-south-1`) and Sydney
(`ap-southeast-2`) through the reusable multi-region ALB module. Mumbai is the
Route 53 PRIMARY endpoint and Sydney is SECONDARY.

The shared public endpoint is `https://ramdevops.site/instant-app`. This root
publishes `https://origin-instant-app.ramdevops.site` for CloudFront to use;
the separate `applications/shared-routing/prod` state owns the public hostname
and path routing. Regional diagnostic
endpoints are `https://mumbai-instant-app.ramdevops.site` and
`https://sydney-instant-app.ramdevops.site`.

Each region runs one directly managed Amazon Linux 2023 `t3.micro` EC2 instance;
Auto Scaling Groups and launch templates are disabled for this application. Bootstrapping
installs Apache `httpd` and serves a page containing:

```text
Welcome to my application
Hostname: <EC2 hostname>
Location: Mumbai or Sydney
```

All taggable resources inherit `env = prod` and
`projectname = instant-app`, in addition to the organization-standard
Application, Project, Environment, ManagedBy, and Owner tags.

## GoDaddy DNS delegation

The Terraform module looks up an existing public Route 53 hosted zone named
`ramdevops.site`; it does not create or own that shared zone. In GoDaddy, replace
the domain's authoritative nameservers with the four NS values assigned to the
Route 53 hosted zone. DNSSEC/DS records at GoDaddy must be coordinated with
Route 53 DNSSEC before changing nameservers. After delegation propagates, Route
53 serves the ACM validation and origin alias records. Deploy this application
before `shared-routing/prod`; CloudFront removes `/instant-app` before forwarding
requests to this origin.

## EC2 key and state backend

The externally managed `ramkey2026` EC2 key pair must exist in Mumbai and
Sydney before planning or deploying. The workflow does not create, copy, or
import key material. Keep its private key outside GitHub and Terraform state.

The workflow exposes `state_backend` as a required choice: `postgres` (default)
or `s3`. Backend-neutral GitHub settings are used: secret
`TF_STATE_CONNECTION` supplies the active database connection and repository
variable `TF_STATE_STORAGE` supplies an object-storage name when required.
Changing the backend of existing state requires a controlled
`terraform init -migrate-state`; workflows never migrate state automatically.

## AWS GitHub credentials

The infrastructure and drift workflows connect to AWS using GitHub Actions
secrets `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`. If temporary STS
credentials are used, also configure `AWS_SESSION_TOKEN`. The IAM identity must
have the required Terraform permissions in Mumbai and Sydney, Route 53 access,
and access to the selected state backend. Never store these values in `.tf`,
`.tfvars`, workflow source, artifacts, or repository variables.

The Application Terraform Drift workflow has no inputs. Every manual run
discovers and checks all application/environment Terraform roots. It reads the
backend from `default_backend` in
`config/terraform/state-management.json`.
