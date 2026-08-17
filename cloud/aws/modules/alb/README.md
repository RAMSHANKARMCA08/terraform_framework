# Application Load Balancer

Reusable ALB module with multi-AZ placement, HTTP-to-HTTPS redirect, regional
ACM certificate support, target group health checks, modern TLS policy, and
instance or IP targets. Target registration is owned by the caller, which allows
this module to support EC2 Auto Scaling, ECS, EKS, and other IP targets.
