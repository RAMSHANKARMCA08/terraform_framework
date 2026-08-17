# instant-app production setup and validation runbook

Use this runbook after Terraform deploys `applications/instant-app/prod`.
Terraform creates the regional infrastructure, EC2 instances, ALBs, regional
ACM certificates, origin Route 53 records, and AWS budget. The shared public
CloudFront distribution is owned by `applications/shared-routing/prod`.

## 1. Prerequisites and AWS access

Install Terraform and AWS CLI, then authenticate with an identity that can read
EC2, ELBv2, ACM, Route 53, and AWS Budgets in the account.

```bash
aws sts get-caller-identity
terraform -chdir=applications/instant-app/prod output
```

Expected Terraform outputs include the main URL, both regional URLs, both ALB
DNS names, both EC2 instance IDs, the Route 53 zone ID, and the budget name.

## 2. Validate EC2 instances

```bash
MUMBAI_INSTANCE=$(terraform -chdir=applications/instant-app/prod output -raw mumbai_instance_id)
SYDNEY_INSTANCE=$(terraform -chdir=applications/instant-app/prod output -raw sydney_instance_id)

aws ec2 describe-instance-status \
  --region ap-south-1 \
  --instance-ids "$MUMBAI_INSTANCE" \
  --include-all-instances

aws ec2 describe-instance-status \
  --region ap-southeast-2 \
  --instance-ids "$SYDNEY_INSTANCE" \
  --include-all-instances
```

Both instances should be `running`, with instance and system status `ok`. They
should use Amazon Linux 2023, instance type `t3.micro`, and key pair
`ramkey2026`.

If an instance is healthy but Apache is not responding, connect using the
matching private key and inspect the bootstrap service:

```bash
sudo systemctl status httpd
sudo journalctl -u httpd --no-pager
sudo cat /var/www/html/index.html
sudo cat /var/www/html/health
curl --fail http://localhost/health
```

The home page should show `Welcome to my application`, the EC2 hostname, and
either `Location: Mumbai` or `Location: Sydney`.

## 3. Validate ALBs and target health

```bash
MUMBAI_ALB=$(terraform -chdir=applications/instant-app/prod output -raw mumbai_alb_dns)
SYDNEY_ALB=$(terraform -chdir=applications/instant-app/prod output -raw sydney_alb_dns)

curl --head "http://${MUMBAI_ALB}/"
curl --head "http://${SYDNEY_ALB}/"
curl --insecure --fail --show-error "https://${MUMBAI_ALB}/health"
curl --insecure --fail --show-error "https://${SYDNEY_ALB}/health"
```

The HTTP requests should report a redirect to HTTPS. Direct ALB HTTPS checks use
`--insecure` only because the certificate is issued for the application
hostnames, not the AWS-generated ALB names. Do not use that option for normal
traffic. Use the regional application URLs for proper TLS validation:

```bash
curl --fail --show-error https://mumbai-instant-app.ramdevops.site/health
curl --fail --show-error https://sydney-instant-app.ramdevops.site/health
```

In EC2 > Target Groups, confirm that the single target in each region is
`healthy`. The target-group health check uses `/health`. If it is unhealthy,
check the instance status, Apache service, target security group, target port,
and ALB security group.

## 4. Validate ACM certificates

Run this in both regions and confirm the certificate status is `ISSUED`:

```bash
aws acm list-certificates --region ap-south-1
aws acm list-certificates --region ap-southeast-2
```

If validation remains pending, verify that the Route 53 public hosted zone is
authoritative for `ramdevops.site` and that its ACM validation CNAME exists.

## 5. Validate origin DNS and shared public routing

```bash
dig NS ramdevops.site
dig +short origin-instant-app.ramdevops.site
dig +short mumbai-instant-app.ramdevops.site
dig +short sydney-instant-app.ramdevops.site

curl --fail --show-error https://origin-instant-app.ramdevops.site/
curl --fail --show-error https://ramdevops.site/instant-app
curl --fail --show-error https://ramdevops.site/instant-app/health
curl --fail --show-error https://mumbai-instant-app.ramdevops.site/
curl --fail --show-error https://sydney-instant-app.ramdevops.site/
```

The origin hostname uses Route 53 failover routing. Mumbai is PRIMARY and Sydney
is SECONDARY. CloudFront routes `/instant-app*` to that hostname and removes the
prefix before forwarding. Under normal conditions the public URL returns the
Mumbai page. Regional hostnames always address their corresponding ALBs.

DNS answers for alias records may be IP addresses rather than ALB names. Use
`nslookup` if `dig` is unavailable.

## 6. Test regional failover

Run failover testing only during an approved test window. Temporarily stopping
Apache on the Mumbai instance is preferable to deleting or modifying Terraform
resources:

```bash
sudo systemctl stop httpd
```

Wait until the Mumbai ALB target is unhealthy and Route 53 health evaluation has
propagated. Repeated requests to `https://ramdevops.site/instant-app` should then
show `Location: Sydney`. DNS, CloudFront, and health transitions are not
immediate because of health-check intervals, thresholds, and resolver caching.

Restore Mumbai immediately after the test:

```bash
sudo systemctl start httpd
curl --fail http://localhost/health
```

Confirm that the Mumbai target returns to `healthy` and the main URL eventually
returns the Mumbai page again. Do not leave this manual service change in place.

## 7. Validate tags and budget

Taggable resources should include at least:

```text
env = prod
projectname = instant-app
```

Confirm the Terraform-managed budget exists:

```bash
BUDGET_NAME=$(terraform -chdir=applications/instant-app/prod output -raw budget_name)
aws budgets describe-budget \
  --region us-east-1 \
  --account-id "$(aws sts get-caller-identity --query Account --output text)" \
  --budget-name "$BUDGET_NAME"
```

Cost Explorer data can take time to appear and must be enabled once per AWS
account before cost reports work.

## 8. Manual configuration excluded from Terraform

The following account or external-system setup is intentionally not owned by
this application root:

1. Create or retain the shared public Route 53 hosted zone `ramdevops.site`.
2. In GoDaddy, delegate `ramdevops.site` to the four Route 53 nameservers. Keep
   DNSSEC/DS configuration consistent with Route 53.
3. Configure GitHub AWS credentials and the selected Terraform state-backend
   credentials or variables.
4. Add the OpenSSH public key to GitHub secret `AWS_EC2_KEYPAIR`. The workflow
   imports it as `ramkey2026` when the regional key pair is absent. Never store
   the private PEM in GitHub.
5. Retain the matching `ramkey2026.pem` private key securely for emergency SSH;
   AWS cannot download an existing private key again.
6. Provision the shared S3 or PostgreSQL state infrastructure before initializing
   this root. Backend selection comes from
   `config/terraform/state-management.json`.
7. Deploy `shared-routing/prod` after both origins; it owns the apex aliases,
   CloudFront distribution, and public TLS certificate.
8. Enable AWS Cost Explorer and activate the `env` and `projectname` cost
   allocation tags if cost reporting by application and environment is needed.

Do not manually edit Terraform-managed VPCs, subnets, route tables, security
groups, instances, ALBs, target groups, ACM records, origin DNS records, or
the budget. Put durable changes into Terraform and redeploy.

## 9. Workflow validation

Run the manual `Application Deployment` workflow with:

```text
appname: instant-app
environment: prod
action: CHECK_DRIFT
```

A clean result confirms that no managed infrastructure was changed manually.
The repository-wide `Application Terraform Drift` workflow can also check every
application and environment without inputs.

## 10. Deletion verification

Destroy `shared-routing/prod` first if both public routes are being retired.
Then use the manual `Application Delete` workflow with `instant-app` and `prod`.
It should remove the application-owned regional EC2, ALB,
networking, ACM, DNS, and budget resources from Terraform state. It must not
delete the shared Route 53 hosted zone, external GoDaddy configuration, shared
state backend, GitHub settings, or an existing/imported EC2 key pair. Deleting
this origin does not delete the separately managed CloudFront router.

After deletion, confirm the two instance IDs and ALBs no longer exist and that
the three origin/diagnostic DNS records no longer resolve. Review the final destroy
plan before approval so shared resources are not included.
