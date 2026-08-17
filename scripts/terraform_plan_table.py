import argparse
import json
from pathlib import Path
from typing import Any


SENSITIVE = "<sensitive>"


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


def row(change: str, resource: dict[str, Any], before: Any, after: Any) -> str:
    return (
        f"| {change} | `{resource.get('type', 'unknown')}` | "
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
        "| Change | Resource | Resource Name | From | To |",
        "|---|---|---|---|---|",
    ]
    lines.extend(rows or ["| No changes | N/A | N/A | N/A | N/A |"])
    report = "\n".join(lines) + "\n"
    Path(args.output).write_text(report, encoding="utf-8")
    print(report, end="")


if __name__ == "__main__":
    main()
