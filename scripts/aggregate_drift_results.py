import argparse
import json
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser(description="Aggregate application drift results.")
    parser.add_argument("--reports-dir", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    results = []
    for path in sorted(Path(args.reports_dir).glob("*.json")):
        results.append(json.loads(path.read_text(encoding="utf-8")))

    drifted = [result for result in results if result["status"] == "DRIFT"]
    errors = [result for result in results if result["status"] == "ERROR"]
    summary = {
        "has_drift": bool(drifted),
        "has_errors": bool(errors),
        "checked": len(results),
        "drifted": len(drifted),
        "results": results,
    }
    Path(args.output).write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print(f"has_drift={'true' if drifted else 'false'}")
    print(f"has_errors={'true' if errors else 'false'}")
    print(f"checked={len(results)}")
    print(f"drifted={len(drifted)}")


if __name__ == "__main__":
    main()
