import argparse
import json
from pathlib import Path


def planned_types(plan: dict) -> dict[str, int]:
    counts: dict[str, int] = {}
    for resource in plan.get("resource_changes", []):
        actions = resource.get("change", {}).get("actions", [])
        if actions in (["no-op"], ["read"], ["delete"]):
            continue
        resource_type = resource.get("type", "unknown")
        counts[resource_type] = counts.get(resource_type, 0) + 1
    return counts


def add_row(rows: list[str], service: str, evidence: str, free_tier: str, cost: str) -> None:
    rows.append(f"| {service} | {evidence} | {free_tier} | {cost} |")


def build_report(plan: dict) -> str:
    types = planned_types(plan)
    rows: list[str] = []

    instance_count = types.get("aws_instance", 0)
    launch_template_count = types.get("aws_launch_template", 0)
    if instance_count or launch_template_count:
        evidence = f"{instance_count} EC2 instance(s)"
        if launch_template_count:
            evidence += f", {launch_template_count} launch template(s)"
        add_row(
            rows,
            "Amazon EC2 and EBS",
            evidence,
            "Credits or limited instance/storage allowance may apply; multiple always-on instances can exceed it.",
            "Instance hours, root EBS volumes, snapshots, and data transfer can be charged.",
        )

    load_balancers = types.get("aws_lb", 0)
    if load_balancers:
        add_row(
            rows,
            "Elastic Load Balancing",
            f"{load_balancers} load balancer(s)",
            "Credits or limited ALB hours/LCUs may apply; allowances are shared across load balancers.",
            "ALB hours, LCUs, processed data, and public IPv4 addresses can be charged.",
        )

    nat_gateways = types.get("aws_nat_gateway", 0)
    if nat_gateways:
        add_row(
            rows,
            "NAT Gateway",
            f"{nat_gateways} NAT gateway(s)",
            "No traditional always-free allowance; account credits may offset charges.",
            "Each gateway-hour, each GB processed, public IPv4, and data transfer can be charged.",
        )

    elastic_ips = types.get("aws_eip", 0)
    if elastic_ips:
        add_row(
            rows,
            "Amazon VPC public IPv4",
            f"{elastic_ips} Elastic IP address(es)",
            "Public IPv4 addresses are not generally free; credits may offset charges.",
            "Hourly charge applies to in-use and idle public IPv4 addresses.",
        )

    route53_records = types.get("aws_route53_record", 0)
    if route53_records:
        add_row(
            rows,
            "Amazon Route 53",
            f"{route53_records} DNS record(s)",
            "Not generally covered by the traditional Free Tier.",
            "Existing hosted-zone and DNS-query charges may apply; eligible alias queries are free.",
        )

    if any(name in types for name in ("aws_instance", "aws_lb", "aws_nat_gateway")):
        add_row(
            rows,
            "AWS Data Transfer",
            "Networked compute/load-balancing resources",
            "Free data-transfer allowances or credits depend on account plan and traffic path.",
            "Internet, inter-Region, cross-AZ, NAT, and load-balancer processing charges may apply.",
        )

    lines = [
        "## AWS Cost-Impact Summary",
        "",
        "> This is a service-level warning derived from planned resource types, not a price quote. Free Tier eligibility, credits, region, runtime, and traffic determine the final bill.",
        "",
        "| Potentially chargeable service | Planned evidence | Free Tier consideration | Cost drivers |",
        "|---|---|---|---|",
    ]
    lines.extend(rows or ["| None identified | No new or updated known billable resource types | N/A | Review the complete plan for indirect charges. |"])
    lines.extend(
        [
            "",
            "Resources such as VPCs, subnets, route tables, security groups, internet gateways, ACM public certificates, and AWS Budgets are omitted because they normally have no direct base hourly charge. Their usage or connected services can still generate charges.",
        ]
    )
    return "\n".join(lines) + "\n"


def main() -> None:
    parser = argparse.ArgumentParser(description="Create an AWS service cost-impact table from a Terraform plan.")
    parser.add_argument("plan_json")
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    plan = json.loads(Path(args.plan_json).read_text(encoding="utf-8"))
    report = build_report(plan)
    Path(args.output).write_text(report, encoding="utf-8")
    print(report, end="")


if __name__ == "__main__":
    main()
