import argparse
import json
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser(description="Create one machine-readable drift result.")
    parser.add_argument("--application", required=True)
    parser.add_argument("--environment", required=True)
    parser.add_argument("--status", choices=("CLEAN", "DRIFT", "ERROR"), required=True)
    parser.add_argument("--report", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    report = Path(args.report).read_text(encoding="utf-8", errors="replace")
    result = {
        "application": args.application,
        "environment": args.environment,
        "status": args.status,
        "details": report[-100_000:],
    }
    Path(args.output).write_text(json.dumps(result, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
