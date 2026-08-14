import argparse
import os
import smtplib
import ssl
from email.message import EmailMessage
from pathlib import Path

import yaml


def required_env(name: str) -> str:
    value = os.environ.get(name)
    if not value:
        raise RuntimeError(f"Missing required environment variable: {name}")
    return value


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--contacts", required=True)
    parser.add_argument("--environment", required=True)
    parser.add_argument("--component", required=True)
    parser.add_argument("--run-url", required=True)
    args = parser.parse_args()

    contacts = yaml.safe_load(Path(args.contacts).read_text(encoding="utf-8"))
    recipients = sorted({
        level["email"]
        for app in contacts["applications"].values()
        for level in (app["l1"], app["l2"])
    })

    message = EmailMessage()
    message["Subject"] = (
        f"[Terraform drift] {args.environment} {args.component}"
    )
    message["From"] = required_env("SMTP_FROM")
    message["To"] = ", ".join(recipients)
    message.set_content(
        f"Terraform drift was detected.\n\n"
        f"Environment: {args.environment}\n"
        f"Component: {args.component}\n"
        f"Workflow run: {args.run_url}\n\n"
        "Review the saved plan in the workflow logs. Do not apply automatically."
    )

    host = required_env("SMTP_HOST")
    port = int(os.environ.get("SMTP_PORT", "587"))
    with smtplib.SMTP(host, port, timeout=30) as server:
        server.starttls(context=ssl.create_default_context())
        server.login(required_env("SMTP_USERNAME"), required_env("SMTP_PASSWORD"))
        server.send_message(message)


if __name__ == "__main__":
    main()
