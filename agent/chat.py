"""Console chat with the Drop-Ship Investigator agent, with a human approval step.

- Read tools run automatically.
- Any other tool call stops and shows you the exact tool and arguments. Nothing is written to
  Business Central unless you type 'yes'.
- Every decision is appended to approvals.log as an audit trail.
- The first time, Foundry asks you to sign in to Business Central (OAuth consent).

Usage:
    python chat.py
"""

import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

from azure.ai.projects import AIProjectClient
from azure.identity import DefaultAzureCredential
from dotenv import load_dotenv

AUDIT_LOG = Path(__file__).parent / "approvals.log"
MAX_ROUNDS = 10  # safety limit on consent/approval round trips for one question


def item_field(item, name):
    """Read a field from a response output item, including types the SDK does not know yet."""
    value = getattr(item, name, None)
    if value is None and getattr(item, "model_extra", None):
        value = item.model_extra.get(name)
    return value


def pretty_arguments(arguments) -> str:
    if isinstance(arguments, str):
        try:
            arguments = json.loads(arguments)
        except json.JSONDecodeError:
            return arguments
    return json.dumps(arguments, indent=2, ensure_ascii=False)


def audit(tool: str, arguments, approved: bool, reason: str) -> None:
    entry = {
        "time": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "tool": tool,
        "arguments": arguments,
        "approved": approved,
        "reason": reason,
    }
    with AUDIT_LOG.open("a", encoding="utf-8") as log:
        log.write(json.dumps(entry, ensure_ascii=False, default=str) + "\n")


def ask_approval(item) -> dict:
    tool = item_field(item, "name") or "<unknown tool>"
    arguments = item_field(item, "arguments")
    print("\n" + "=" * 70)
    print("APPROVAL NEEDED: the agent wants to call a tool that is not read-only")
    print(f"  Server:    {item_field(item, 'server_label')}")
    print(f"  Tool:      {tool}")
    print("  Arguments:")
    print("    " + pretty_arguments(arguments).replace("\n", "\n    "))
    print("=" * 70)
    answer = input("Type 'yes' to approve, anything else to reject: ").strip().lower()
    approved = answer == "yes"
    reason = "" if approved else input("Reason for rejecting (sent to the agent): ").strip()
    audit(tool, arguments, approved, reason)
    print("Approved." if approved else "Rejected.")

    response = {
        "type": "mcp_approval_response",
        "approval_request_id": item.id,
        "approve": approved,
    }
    if reason:
        response["reason"] = reason
    return response


def run_turn(openai, agent_ref: dict, question: str, previous_response_id):
    response = openai.responses.create(
        input=question,
        previous_response_id=previous_response_id,
        extra_body={"agent_reference": agent_ref},
    )

    for _ in range(MAX_ROUNDS):
        consent_links = [
            item_field(item, "consent_link")
            for item in response.output
            if item.type == "oauth_consent_request"
        ]
        approvals = [item for item in response.output if item.type == "mcp_approval_request"]

        if consent_links:
            print("\nSign in to Business Central to let the agent read data as you:")
            for link in consent_links:
                print(f"  {link}")
            input("Open the link, sign in, close the window, then press Enter here...")
            response = openai.responses.create(
                input=question,
                previous_response_id=response.id,
                extra_body={"agent_reference": agent_ref},
            )
            continue

        if approvals:
            decisions = [ask_approval(item) for item in approvals]
            response = openai.responses.create(
                input=decisions,
                previous_response_id=response.id,
                extra_body={"agent_reference": agent_ref},
            )
            continue

        break
    else:
        print("\nStopped after too many consent/approval rounds.")

    return response


def main() -> None:
    load_dotenv()
    endpoint = os.getenv("PROJECT_ENDPOINT", "").strip()
    if not endpoint:
        sys.exit("Missing PROJECT_ENDPOINT. Copy .env.example to .env and fill it in.")

    project = AIProjectClient(endpoint=endpoint, credential=DefaultAzureCredential())
    openai = project.get_openai_client()
    agent_ref = {"name": os.getenv("AGENT_NAME", "drop-ship-investigator"), "type": "agent_reference"}

    print("Drop-Ship Investigator. Ask a question, or press Enter on an empty line to quit.")
    print("Example: Are there any drop-ship imbalances? Investigate the largest one.\n")

    previous_response_id = None
    while True:
        question = input("You: ").strip()
        if not question:
            break
        response = run_turn(openai, agent_ref, question, previous_response_id)
        previous_response_id = response.id
        print(f"\nAgent: {response.output_text}\n")


if __name__ == "__main__":
    main()
