# myk8sapp one-day EKS test

Deploys one EKS cluster and one public `t3.small` managed worker in Mumbai. The
nginx pod binds host port 80 and is also exposed through NodePort 30080. Route 53
maps `origin-myk8sapp.ramdevops.site` directly to the worker public IP. No load
balancer or NAT gateway is created. The separate shared CloudFront router exposes
`https://ramdevops.site/myk8sapp` and forwards to NodePort `30080` after removing
the `/myk8sapp` prefix.

This is test-only: the EKS API and worker HTTP ports are public, there is one
worker, there is no HTTPS, and managed-node replacement changes the public IP.
Run Terraform again to refresh Route 53 after replacement, and delete the stack
immediately after the one-day test to stop the EKS control-plane charge.
