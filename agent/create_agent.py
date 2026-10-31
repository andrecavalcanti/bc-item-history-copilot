"""Create (or add a new version of) the Investigation Assistant agent in Microsoft Foundry.

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
# Anything NOT in this list (including Create_InvestigationFinding_PAG58007, and any tool with a name
# we did not expect) requires approval, so a wrong name fails safe: it asks instead of acting.
READ_ONLY_TOOLS = [
    # Shared
    "List_ItemEntries_PAG58004",
    "List_InvestigationFindings_PAG58007",
    # Drop shipment module
    "List_DropShipImbalances_QRY58001",
    "List_DropShipSalesLines_PAG58005",
    "List_DropShipPurchaseLines_PAG58006",
    # Negative inventory module
    "List_NegativeInventoryLines_QRY58002",
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
        server_description="Business Central inventory data and investigation findings.",
        project_connection_id=required("MCP_CONNECTION_NAME"),
        headers=headers,
        require_approval=MCPToolRequireApproval(
            never=MCPToolFilter(tool_names=READ_ONLY_TOOLS),
        ),
    )


def load_instructions() -> str:
    """General instructions plus one section per problem module (agent/modules/*.md)."""
    folder = Path(__file__).parent
    parts = [(folder / "instructions.md").read_text(encoding="utf-8")]
    for module in sorted((folder / "modules").glob("*.md")):
        parts.append(module.read_text(encoding="utf-8"))
    return "\n\n".join(parts)


def main() -> None:
    load_dotenv()
    instructions = load_instructions()

    project = AIProjectClient(
        endpoint=required("PROJECT_ENDPOINT"),
        credential=DefaultAzureCredential(),
    )

    agent = project.agents.create_version(
        agent_name=os.getenv("AGENT_NAME", "bc-investigation-assistant"),
        definition=PromptAgentDefinition(
            model=required("MODEL_DEPLOYMENT"),
            instructions=instructions,
            tools=[build_bc_mcp_tool()],
        ),
    )
    print(f"Agent ready: {agent.name} (version {agent.version})")
    modules = sorted(p.stem for p in (Path(__file__).parent / "modules").glob("*.md"))
    print(f"Problem modules: {', '.join(modules)}")
    print("Run 'python chat.py' to start an investigation.")


if __name__ == "__main__":
    main()
