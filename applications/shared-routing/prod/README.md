# Shared production routing

This Terraform root owns the shared CloudFront distribution and the Route 53
A/AAAA aliases for `ramdevops.site`. It routes `/instant-app*` to the
multi-region ALB origin and `/myk8sapp*` to the EKS NodePort origin. CloudFront
removes the application prefix before forwarding, so existing workloads continue
to serve `/` and `/health`.

Deploy `instant-app/prod` and `myk8sapp/prod` first so their origin DNS records
exist, then deploy this root. Destroy this root before deleting either origin.
The public URLs are:

- `https://ramdevops.site/instant-app`
- `https://ramdevops.site/myk8sapp`

The root URL redirects to `/instant-app`. This shared state deliberately remains
separate from both application states so deleting one application cannot delete
the other application's public router.

This state also owns `shared-routing-prod-monthly`, a USD 10 monthly budget for
costs tagged `projectname = shared-routing`. Cost allocation tags and Cost
Explorer require account-level activation.
