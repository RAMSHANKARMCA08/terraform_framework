import argparse
import html
import json
import os
import smtplib
import ssl
from email.message import EmailMessage
from pathlib import Path


def required_env(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        raise RuntimeError(f"Missing required environment variable: {name}")
    return value


def main() -> None:
    parser = argparse.ArgumentParser(description="Email a Terraform drift report.")
    parser.add_argument("--run-url", required=True)
    parser.add_argument("--summary", required=True)
    args = parser.parse_args()

    recipients = [
        address.strip()
        for address in required_env("SMTP_TO").replace(";", ",").split(",")
        if address.strip()
    ]
    if not recipients:
        raise RuntimeError("SMTP_TO must contain at least one email address")

    summary = json.loads(Path(args.summary).read_text(encoding="utf-8"))
    drifted = [result for result in summary["results"] if result["status"] == "DRIFT"]
    if not drifted:
        print("No drift detected; email was not sent.")
        return

    message = EmailMessage()
    message["Subject"] = (
        f"[DRIFT] Terraform: {len(drifted)} application environment(s)"
    )
    message["From"] = required_env("SMTP_FROM")
    message["To"] = ", ".join(recipients)
    message.set_content(
        "Terraform drift was detected.\n\n"
        + "Application | Environment | Status\n"
        + "------------|-------------|-------\n"
        + "\n".join(
            f"{item['application']} | {item['environment']} | {item['status']}"
            for item in drifted
        )
        + f"\n\nWorkflow run: {args.run_url}\n"
    )
    rows = "".join(
        "<tr>"
        f"<td>{html.escape(item['application'])}</td>"
        f"<td>{html.escape(item['environment'])}</td>"
        f"<td><strong>{html.escape(item['status'])}</strong></td>"
        f"<td><pre>{html.escape(item['details'][-30_000:])}</pre></td>"
        "</tr>"
        for item in drifted
    )
    message.add_alternative(
        "<!doctype html><html><body>"
        "<h2>Terraform Drift Report</h2>"
        f"<p>Checked: {summary['checked']} &nbsp; Drifted: {summary['drifted']}</p>"
        "<table border='1' cellpadding='6' cellspacing='0'>"
        "<thead><tr><th>Application</th><th>Environment</th><th>Status</th>"
        "<th>Drift details</th></tr></thead>"
        f"<tbody>{rows}</tbody></table>"
        f"<p><a href='{html.escape(args.run_url)}'>Open workflow run</a></p>"
        "</body></html>",
        subtype="html",
    )

    host = required_env("SMTP_HOST")
    port = int(os.environ.get("SMTP_PORT", "587"))
    username = required_env("SMTP_USERNAME")
    password = required_env("SMTP_PASSWORD")

    context = ssl.create_default_context()
    if port == 465:
        with smtplib.SMTP_SSL(host, port, timeout=30, context=context) as server:
            server.login(username, password)
            server.send_message(message)
    else:
        with smtplib.SMTP(host, port, timeout=30) as server:
            server.ehlo()
            server.starttls(context=context)
            server.ehlo()
            server.login(username, password)
            server.send_message(message)


if __name__ == "__main__":
    main()
