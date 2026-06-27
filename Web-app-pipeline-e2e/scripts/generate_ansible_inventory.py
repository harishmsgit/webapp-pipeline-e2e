#!/usr/bin/env python3
"""Generate a simple Ansible inventory from Terraform output JSON."""

import argparse
import json
from pathlib import Path


def output_value(outputs, key, default=None):
    item = outputs.get(key, {})
    return item.get("value", default)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--terraform-output", required=True)
    parser.add_argument("--inventory", required=True)
    parser.add_argument("--remote-user", default="ubuntu")
    parser.add_argument("--public-ip", default=None, help="Optional override public IP for the management host")
    args = parser.parse_args()

    outputs = json.loads(Path(args.terraform_output).read_text(encoding="utf-8"))
    public_ip = args.public_ip or output_value(outputs, "management_ec2_public_ip")
    if not public_ip:
        raise SystemExit("Terraform output management_ec2_public_ip is empty; cannot build Ansible inventory.")

    inventory_path = Path(args.inventory)
    inventory_path.parent.mkdir(parents=True, exist_ok=True)
    inventory_path.write_text(
        "[management]\n"
        f"management-ec2 ansible_host={public_ip} ansible_user={args.remote_user}\n",
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
