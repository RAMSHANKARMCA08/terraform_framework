# Shared production routing validation

Run these checks after both application origins and `shared-routing/prod` have
been deployed.

```bash
terraform -chdir=applications/shared-routing/prod output
dig +short ramdevops.site A
dig +short ramdevops.site AAAA
curl --head https://ramdevops.site/
curl --fail --show-error https://ramdevops.site/instant-app
curl --fail --show-error https://ramdevops.site/instant-app/health
curl --fail --show-error https://ramdevops.site/myk8sapp
```

The root must redirect to `/instant-app`. The first application must show the
Mumbai page during normal operation; the second must show the nginx test page.
In CloudFront, confirm that the distribution is `Deployed`, both origins exist,
and the ordered behaviors are `/instant-app*` and `/myk8sapp*`.

Manual prerequisites excluded from Terraform are the existing public Route 53
zone, GoDaddy nameserver delegation, GitHub AWS/state credentials, and deployment
of both origin application roots. CloudFront changes can take several minutes to
propagate. Do not manually change distribution behaviors or the apex DNS aliases.
Before the first deployment, check whether an unmanaged A or AAAA record already
uses the environment hostname; resolve that ownership conflict instead of
overwriting it outside Terraform.

To remove all three stacks, destroy `shared-routing/prod` first, followed by the
two application roots. Verify that the apex CloudFront aliases are removed while
the shared hosted zone and GoDaddy delegation remain.
