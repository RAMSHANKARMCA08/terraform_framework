# CloudFront path router

Creates one environment-level CloudFront distribution, an ACM certificate in
`us-east-1`, and Route 53 A/AAAA aliases. Requests under `/<application>` are
routed to the configured custom origin and the application prefix is removed
before forwarding. The root redirects to the configured default application.

Use this module from a shared routing state, not from an individual application
state. Production owns the apex hostname; other environments own
`<environment>.<domain>`.
