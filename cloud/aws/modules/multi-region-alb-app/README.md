# Multi-region ALB application

Reusable active/passive AWS application stack. It creates equivalent Mumbai
and Sydney networking and compute, regional ACM certificates, direct regional
DNS aliases, and a Route 53 PRIMARY/SECONDARY failover alias. The public hosted
zone is looked up and is never owned by this module.

The caller must pass `aws.mumbai` and `aws.sydney` provider configurations. A
dedicated Terraform root should call this module so each application/environment
retains isolated state ownership.
