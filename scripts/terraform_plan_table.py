import argparse
import json
import re
from pathlib import Path
from typing import Any


SENSITIVE = "<sensitive>"
REGION_NAMES = ("mumbai", "sydney")
INR_PER_USD = 87.0

# Indicative base prices only. Traffic, LCUs, storage, taxes, and account credits
# are deliberately excluded; the separate cost-impact report explains those.
HOURLY_USD = {
    "aws_eip": {"default": 0.005},
    "aws_instance": {
        "mumbai:t3.micro": 0.0128,
        "sydney:t3.micro": 0.0132,
    },
    "aws_lb": {
        "mumbai": 0.0252,
        "sydney": 0.0252,
    },
    "aws_nat_gateway": {
        "mumbai": 0.052,
        "sydney": 0.059,
    },
}

FREE_RESOURCE_TYPES = {
    "aws_acm_certificate",
    "aws_acm_certificate_validation",
    "aws_budgets_budget",
    "aws_iam_instance_profile",
    "aws_iam_role",
    "aws_iam_role_policy",
    "aws_internet_gateway",
    "aws_lb_listener",
    "aws_lb_target_group",
    "aws_lb_target_group_attachment",
    "aws_route_table",
    "aws_route_table_association",
    "aws_security_group",
    "aws_subnet",
    "aws_vpc",
    "aws_vpc_security_group_egress_rule",
    "aws_vpc_security_group_ingress_rule",
}

USAGE_BASED_RESOURCE_TYPES = {
    "aws_cloudfront_distribution",
    "aws_route53_record",
}


def redact(value: Any, sensitive: Any) -> Any:
    if sensitive is True:
        return SENSITIVE
    if isinstance(value, dict):
        sensitive_map = sensitive if isinstance(sensitive, dict) else {}
        return {key: redact(item, sensitive_map.get(key)) for key, item in value.items()}
    if isinstance(value, list):
        sensitive_list = sensitive if isinstance(sensitive, list) else []
        return [
            redact(item, sensitive_list[index] if index < len(sensitive_list) else None)
            for index, item in enumerate(value)
        ]
    return value


def changed_state(before: Any, after: Any) -> tuple[Any, Any]:
    if not isinstance(before, dict) or not isinstance(after, dict):
        return before, after
    keys = sorted(key for key in before.keys() | after.keys() if before.get(key) != after.get(key))
    return ({key: before.get(key) for key in keys}, {key: after.get(key) for key in keys})


def display(value: Any) -> str:
    if value is None:
        return "N/A"
    rendered = json.dumps(value, sort_keys=True, separators=(",", ":"), default=str)
    if len(rendered) > 500:
        rendered = rendered[:497] + "..."
    return rendered.replace("|", "\\|").replace("\n", " ")


def resource_region(resource: dict[str, Any]) -> str:
    address = str(resource.get("address", resource.get("name", ""))).lower()
    for region in REGION_NAMES:
        if re.search(rf"(?:^|[^a-z0-9]){region}(?:[^a-z0-9]|$)", address):
            return region
    return "N/A"


def cost_state(resource: dict[str, Any], after: Any) -> str:
    resource_type = resource.get("type", "unknown")
    region = resource_region(resource)

    if resource_type in FREE_RESOURCE_TYPES:
        return "Free"
    if resource_type in USAGE_BASED_RESOURCE_TYPES:
        return "Charged (usage-based)"

    rates = HOURLY_USD.get(resource_type)
    if rates:
        rate_key = region
        if resource_type == "aws_instance" and isinstance(after, dict):
            instance_type = after.get("instance_type")
            if instance_type:
                rate_key = f"{region}:{instance_type}"
        hourly_usd = rates.get(rate_key, rates.get("default"))
        if hourly_usd is not None:
            daily_inr = hourly_usd * 24 * INR_PER_USD
            if resource_type == "aws_instance" and isinstance(after, dict) and after.get("instance_type") == "t3.micro":
                return f"Free-tier eligible; charged otherwise (Rs {daily_inr:.2f}/day)"
            return f"Charged (Rs {daily_inr:.2f}/day)"

    return "Review pricing"


def row(change: str, resource: dict[str, Any], before: Any, after: Any) -> str:
    priced_state = after if after is not None else before
    return (
        f"| {change} | {resource_region(resource)} | {cost_state(resource, priced_state)} | "
        f"`{resource.get('type', 'unknown')}` | "
        f"`{resource.get('address', resource.get('name', 'unknown'))}` | "
        f"{display(before)} | {display(after)} |"
    )


def main() -> None:
    parser = argparse.ArgumentParser(description="Convert terraform show -json output to Markdown.")
    parser.add_argument("plan_json")
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    plan = json.loads(Path(args.plan_json).read_text(encoding="utf-8"))
    rows: list[str] = []
    totals = {"New": 0, "Modify": 0, "Delete": 0}

    for resource in plan.get("resource_changes", []):
        change = resource.get("change", {})
        actions = change.get("actions", [])
        if actions in (["no-op"], ["read"]):
            continue

        before = redact(change.get("before"), change.get("before_sensitive"))
        after = redact(change.get("after"), change.get("after_sensitive"))

        if actions == ["create"]:
            rows.append(row("New", resource, None, after))
            totals["New"] += 1
        elif actions == ["delete"]:
            rows.append(row("Delete", resource, before, None))
            totals["Delete"] += 1
        elif "delete" in actions and "create" in actions:
            rows.append(row("Delete", resource, before, None))
            rows.append(row("New", resource, None, after))
            totals["Delete"] += 1
            totals["New"] += 1
        else:
            before_changed, after_changed = changed_state(before, after)
            rows.append(row("Modify", resource, before_changed, after_changed))
            totals["Modify"] += 1

    lines = [
        "## Terraform Plan Summary",
        "",
        f"**New:** {totals['New']} | **Modify:** {totals['Modify']} | **Delete:** {totals['Delete']}",
        "",
        "| Change | Region | Cost State | Resource | Resource Name | From | To |",
        "|---|---|---|---|---|---|---|",
    ]
    lines.extend(rows or ["| No changes | N/A | N/A | N/A | N/A | N/A | N/A |"])
    lines.extend(
        [
            "",
            f"> Cost State is an indicative base-cost estimate using Rs {INR_PER_USD:.2f}/USD. It excludes usage, storage, data transfer, taxes, credits, and shared Free Tier limits; verify with AWS Pricing Calculator before deployment.",
        ]
    )
    report = "\n".join(lines) + "\n"
    Path(args.output).write_text(report, encoding="utf-8")
    print(report, end="")


if __name__ == "__main__":
    main()
