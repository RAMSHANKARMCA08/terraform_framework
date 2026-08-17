# myk8sapp initial setup and test runbook

Use this runbook after Terraform deploys `applications/myk8sapp/prod`. This stack
is a temporary, public, single-worker EKS test and is not production-ready.

## 1. Local tools and AWS access

Install compatible versions of the AWS CLI and `kubectl`. Configure AWS
credentials with permission to describe the EKS cluster, EC2 worker, Route 53
record, and Kubernetes API authentication.

```bash
aws sts get-caller-identity
aws eks describe-cluster \
  --region ap-south-1 \
  --name myk8sapp-prod \
  --query 'cluster.status' \
  --output text
```

Expected cluster status:

```text
ACTIVE
```

## 2. Configure kubectl

```bash
aws eks update-kubeconfig \
  --region ap-south-1 \
  --name myk8sapp-prod

kubectl cluster-info
kubectl get nodes -o wide
```

Expected result: exactly one worker node in `Ready` state with a public IP.

If authentication fails, confirm the AWS identity running these commands is the
same cluster creator identity or has an EKS access entry with suitable
Kubernetes permissions. Terraform enables cluster-creator administrator access,
but it does not grant access to unrelated IAM users or roles.

## 3. Verify Kubernetes resources

```bash
kubectl get namespace myk8sapp
kubectl get deployment,pods,service -n myk8sapp -o wide
kubectl describe deployment myk8sapp -n myk8sapp
kubectl describe service myk8sapp -n myk8sapp
```

Expected results:

- Deployment reports one desired and one available replica.
- Pod status is `Running` and `Ready`.
- Service type is `NodePort`.
- Service NodePort is `30080`.
- The pod binds host port `80` on the single worker.

Useful troubleshooting commands:

```bash
kubectl get events -n myk8sapp --sort-by='.lastTimestamp'
kubectl logs -n myk8sapp deployment/myk8sapp
kubectl describe pod -n myk8sapp -l app=myk8sapp
```

## 4. Test NodePort and host port

Read the worker address from Terraform:

```bash
terraform -chdir=applications/myk8sapp/prod output -raw worker_public_ip
```

Then test both paths:

```bash
WORKER_IP=$(terraform -chdir=applications/myk8sapp/prod output -raw worker_public_ip)
curl --fail --show-error --verbose "http://${WORKER_IP}:30080/"
curl --fail --show-error --verbose "http://${WORKER_IP}/"
```

Both requests should return the nginx welcome page. Port `30080` is the
CloudFront origin port. Port `80` directly tests the pod's host-port binding.

If either request times out, verify:

```bash
aws ec2 describe-instances \
  --region ap-south-1 \
  --filters 'Name=tag:eks:cluster-name,Values=myk8sapp-prod' \
            'Name=instance-state-name,Values=running' \
  --query 'Reservations[].Instances[].{Id:InstanceId,PublicIp:PublicIpAddress,Groups:SecurityGroups[].GroupId}'
```

The EKS-managed security group must allow public TCP ports `80` and `30080`.
Terraform manages both ingress rules.

## 5. Verify origin DNS and shared CloudFront URL

```bash
aws route53 list-hosted-zones-by-name \
  --dns-name ramdevops.site \
  --query 'HostedZones[0].[Id,Name]' \
  --output table

dig +short origin-myk8sapp.ramdevops.site A
nslookup origin-myk8sapp.ramdevops.site
curl --fail --show-error --verbose http://origin-myk8sapp.ramdevops.site:30080/
curl --fail --show-error --verbose https://ramdevops.site/myk8sapp
```

The origin DNS A record should equal the current worker public IP. The public URL
is owned by `shared-routing/prod`; CloudFront removes `/myk8sapp` and forwards
the request to the origin on NodePort `30080`. Route 53 TTL is 60 seconds,
although recursive resolvers and clients can cache results longer.

## 6. Manual setup excluded from Terraform

The following account/domain tasks are intentionally not owned by this
application state:

1. The public Route 53 hosted zone `ramdevops.site` must already exist.
2. GoDaddy must delegate `ramdevops.site` to the four Route 53 authoritative
   nameservers. Confirm with `dig NS ramdevops.site`.
3. GitHub Actions AWS credentials and state-backend settings must be configured
   using `config/github/sample.env` as the reference.
4. PostgreSQL or S3 state infrastructure must already exist and be accessible.
5. Deploy `shared-routing/prod` after both origins to create the public URL.
6. Cost Explorer must be enabled manually if cost reporting is required.
7. Activate the `projectname` and `env` user-defined cost-allocation tags in AWS
   Billing if tag-filtered cost reporting is required.

No manual Kubernetes manifest application should be necessary; Terraform owns
the namespace, deployment, and service. Avoid `kubectl edit` for lasting changes
because the next Terraform apply can overwrite them and drift checks will not
fully model arbitrary in-cluster edits.

## 7. Worker replacement and DNS repair

The managed worker public IP is ephemeral. If EKS replaces the worker, Route 53
continues pointing to the old address until Terraform refreshes the EC2 data
source and updates the record.

```bash
terraform -chdir=applications/myk8sapp/prod apply -var-file=terraform.tfvars
```

Afterward, repeat the worker-IP, DNS, and curl tests above. Do not manually edit
the Route 53 record unless performing temporary incident recovery; reconcile any
manual change with Terraform afterward.

## 8. Optional test actions

```bash
kubectl rollout restart deployment/myk8sapp -n myk8sapp
kubectl rollout status deployment/myk8sapp -n myk8sapp --timeout=5m
kubectl scale deployment/myk8sapp -n myk8sapp --replicas=0
kubectl scale deployment/myk8sapp -n myk8sapp --replicas=1
```

Because host port 80 is used and there is one worker, keep the deployment at one
replica. A second replica cannot schedule on the same node while port 80 is in
use.

## 9. Teardown verification

Destroy `shared-routing/prod` first if both public routes are being retired.
Then use the Application Delete workflow with:

```text
appname: myk8sapp
environment: prod
confirmation: DELETE
```

After deletion, verify:

```bash
aws eks describe-cluster --region ap-south-1 --name myk8sapp-prod
dig +short origin-myk8sapp.ramdevops.site A
```

The EKS command should report that the cluster does not exist and DNS should no
longer return the origin record. The shared Route 53 hosted zone, GoDaddy domain,
GitHub settings, shared Terraform state backend, and separately managed
CloudFront distribution remain intact.
