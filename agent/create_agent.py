"""Create (or add a new version of) the Drop-Ship Investigator agent in Microsoft Foundry.

The agent uses the Business Central MCP server as its only tool. Read tools run without asking;
every other tool, including creating a finding, needs a person's approval.

Usage:
    python create_agent.py
"""

import base64
import os
import sys
from pathlib import Path

from azure.ai.projects import AIProjectClient
from azure.ai.projects.models import (
    MCPTool,
    MCPToolFilter,
    MCPToolRequireApproval,
    PromptAgentDefinition,
)
from azure.identity import DefaultAzureCredential
from dotenv import load_dotenv

BC_MCP_SERVER_URL = "https://mcp.businesscentral.dynamics.com"

# Tools that only read data. Names follow the BC pattern List_<EntitySetName>_<PAG|QRY><ID>.
# Anything NOT in this list (including Create_DropShipFinding_PAG50107, and any tool with a name
# we did not expect) requires approval, so a wrong name fails safe: it asks instead of acting.
READ_ONLY_TOOLS = [
    "List_DropShipImbalances_QRY50101",
    "List_DropShipEntries_PAG50104",
    "List_DropShipSalesLines_PAG50105",
    "List_DropShipPurchaseLines_PAG50106",
    "List_DropShipFindings_PAG50107",
]


def required(name: str) -> str:
    value = os.getenv(name, "").strip()
    if not value:
        sys.exit(f"Missing {name}. Copy .env.example to .env and fill it in.")
    return value


def header_value(value: str) -> str:
    """BC MCP headers must be ASCII; other values are sent as =?base64?<value>?=."""
    if value.isascii():
        return value
    encoded = base64.b64encode(value.encode("utf-8")).decode("ascii")
    return f"=?base64?{encoded}?="


def build_bc_mcp_tool() -> MCPTool:
    headers = {
        "TenantId": required("BC_TENANT_ID"),
        "EnvironmentName": required("BC_ENVIRONMENT"),
        "Company": header_value(required("BC_COMPANY")),
    }
    configuration = os.getenv("BC_MCP_CONFIGURATION", "").strip()
    if configuration:
        headers["ConfigurationName"] = header_value(configuration)

    return MCPTool(
        server_label="business_central",
        server_url=BC_MCP_SERVER_URL,
        server_description="Business Central drop-shipment data and findings.",
        project_connection_id=required("MCP_CONNECTION_NAME"),
        headers=headers,
        require_approval=MCPToolRequireApproval(
            never=MCPToolFilter(tool_names=READ_ONLY_TOOLS),
        ),
    )


def main() -> None:
    load_dotenv()
    instructions = (Path(__file__).parent / "instructions.md").read_text(encoding="utf-8")

    project = AIProjectClient(
        endpoint=required("PROJECT_ENDPOINT"),
        credential=DefaultAzureCredential(),
    )

    agent = project.agents.create_version(
        agent_name=os.getenv("AGENT_NAME", "drop-ship-investigator"),
        definition=PromptAgentDefinition(
            model=required("MODEL_DEPLOYMENT"),
            instructions=instructions,
            tools=[build_bc_mcp_tool()],
        ),
    )
    print(f"Agent ready: {agent.name} (version {agent.version})")
    print("Run 'python chat.py' to start an investigation.")


if __name__ == "__main__":
    main()
