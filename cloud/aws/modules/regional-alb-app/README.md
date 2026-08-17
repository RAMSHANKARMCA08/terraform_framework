# Regional ALB application

Creates an internet-facing ALB, HTTPS/redirect listeners, target group, and an
Auto Scaling Group running a small Amazon Linux web application. Networking and
regional ACM certificates are supplied by the caller.

The caller can select an Auto Scaling Group or one directly managed EC2 instance.
Auto Scaling defaults to `min=1`, `desired=1`, `max=1`. The application security
group permits HTTP only from the ALB security group.
