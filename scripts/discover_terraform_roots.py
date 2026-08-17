import argparse
import json
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser(description="Discover application Terraform roots.")
    parser.add_argument("--applications-dir", default="applications")
    parser.add_argument("--environments-dir", default="environments")
    parser.add_argument("--application", default="all")
    parser.add_argument("--environment", default="all")
    args = parser.parse_args()

    roots = []
    base = Path(args.applications_dir)
    valid_environments = {
        path.name for path in Path(args.environments_dir).iterdir() if path.is_dir()
    }
    for application_dir in sorted(path for path in base.iterdir() if path.is_dir()):
        if args.application != "all" and application_dir.name != args.application:
            continue
        for environment_dir in sorted(path for path in application_dir.iterdir() if path.is_dir()):
            if environment_dir.name not in valid_environments:
                continue
            if args.environment != "all" and environment_dir.name != args.environment:
                continue
            if not any(environment_dir.glob("*.tf")):
                continue
            roots.append(
                {
                    "application": application_dir.name,
                    "environment": environment_dir.name,
                    "directory": environment_dir.as_posix(),
                }
            )

    if not roots:
        raise SystemExit("No matching application Terraform roots were found")
    print(json.dumps({"include": roots}, separators=(",", ":")))


if __name__ == "__main__":
    main()
