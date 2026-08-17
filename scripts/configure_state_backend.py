import argparse
import json
from pathlib import Path


def hcl_string(value: str) -> str:
    return json.dumps(value)


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate a Terraform backend declaration.")
    parser.add_argument("--config", default="config/terraform/state-management.json")
    parser.add_argument("--backend", choices=("postgres", "s3"))
    parser.add_argument("--application", required=True)
    parser.add_argument("--environment", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    config = json.loads(Path(args.config).read_text(encoding="utf-8"))
    backend = args.backend or config["default_backend"]
    backend_config = config["backends"][backend]

    if backend == "postgres":
        schema_name = backend_config["schema_name"].format(
            application=args.application,
            environment=args.environment,
        )
        content = (
            "terraform {\n"
            '  backend "pg" {\n'
            f"    schema_name = {hcl_string(schema_name)}\n"
            "  }\n"
            "}\n"
        )
    else:
        state_key = backend_config["key_pattern"].format(
            application=args.application,
            environment=args.environment,
        )
        content = (
            "terraform {\n"
            '  backend "s3" {\n'
            f"    key     = {hcl_string(state_key)}\n"
            f"    region  = {hcl_string(backend_config['region'])}\n"
            "    encrypt = true\n"
            "  }\n"
            "}\n"
        )

    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(content, encoding="utf-8")
    print(f"Configured Terraform backend '{backend}' in {output}")


if __name__ == "__main__":
    main()
