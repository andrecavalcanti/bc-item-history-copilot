# Investigation Assistant agent

A **Microsoft Foundry** agent that investigates inventory problems in **Business Central online**
through the **Business Central MCP server**, and proposes a root cause and fix that a person must approve.

It knows several **problem types**, each one a module: **drop shipment** and **negative inventory** today.
Adding a problem type does not need a new app; see [Adding a problem module](#adding-a-problem-module).

```mermaid
flowchart LR
    You[You in chat.py] --> Agent[Foundry agent]
    Agent -- read tools, no approval --> MCP[BC MCP server]
    Agent -- create finding --> Gate{Your approval}
    Gate -- yes --> MCP
    Gate -- no --> Agent
    MCP --> BC[(Business Central sandbox)]
    BC --> Review[BCIA Investigation Findings page]
    Review --> Person[Person accepts, fixes, marks done]
```

## Safety design

Four layers limit what the agent can do. If one fails, the next still holds:

| Layer | What it limits |
|---|---|
| BC MCP configuration | Only the listed API objects are exposed. Only the findings page allows create; nothing allows modify or delete. |
| BC API objects | The data pages and queries are read-only. The findings page is read and create only. A new finding is always forced to status **New** and must name its problem type. |
| Foundry approval policy | Only the known read tools run without approval. Any other tool call, including tools with unexpected names, stops for your approval. |
| BC permissions | The agent acts as the signed-in user, with that user's permissions, and the audit trail shows who did what. |

The agent never posts, changes or deletes ledger entries or documents. A person reviews findings on the
**BCIA Investigation Findings** page (Accept, Reject, Mark as Done) and carries out the fix.

## BC objects used by the agent

| Object | Module | Purpose | MCP tool name |
|---|---|---|---|
| Page 58004 BCIA Item Entries API | Shared | Item ledger entries with order links and flags | `List_ItemEntries_PAG58004` |
| Page 58007 BCIA Investigation Finding API | Shared | Existing findings, and creating new ones | `List_InvestigationFindings_PAG58007`, `Create_InvestigationFinding_PAG58007` |
| Query 58001 BCIA Drop Ship Imbalance API | Drop shipment | Item/location combinations that don't net to zero | `List_DropShipImbalances_QRY58001` |
| Page 58005 BCIA Drop Ship Sales Lines API | Drop shipment | Open drop-ship sales lines and linked purchase lines | `List_DropShipSalesLines_PAG58005` |
| Page 58006 BCIA Drop Ship Purch Lines API | Drop shipment | Open drop-ship purchase lines and linked sales lines | `List_DropShipPurchaseLines_PAG58006` |
| Query 58002 BCIA Negative Inventory API | Negative inventory | Open outbound entries not covered by stock | `List_NegativeInventoryLines_QRY58002` |
| Page 58008 BCIA Investigation Findings | Shared | Human review | (not exposed) |

All API objects use publisher `andreCavalcanti`, group `itemHistory`, version `v1.0`.

---

## Setup

You need: a Business Central online sandbox where you are admin, your Foundry project, Python 3.10+
and the Azure CLI.

### 1. Publish the app to your BC online sandbox

The BC MCP server works only with Business Central online, not with containers.

Add a SaaS configuration to `dsi-item-history-copilot/.vscode/launch.json`:

```json
{
  "name": "BC online sandbox",
  "type": "al",
  "request": "launch",
  "environmentType": "Sandbox",
  "environmentName": "Sandbox",
  "tenant": "<your BC tenant ID or domain>",
  "startupObjectId": 58008,
  "startupObjectType": "Page",
  "schemaUpdateMode": "ForceSync"
}
```

Select it in **Run and Debug**, run **AL: Download symbols**, then press **F5**.
Assign the **BCIA Investigation** permission set to your user.

### 2. Create some test data

You need at least one problem to investigate:
- **Drop shipment:** recreate your **Test B** scenario, or any scenario where drop-ship receipts and
  shipments for an item and location don't match. Check it on **Item Ledger Entries** filtered on
  **Drop Shipment = Yes**.
- **Negative inventory:** on an item with no stock at a location, post a sales order (or a negative
  item journal line) at that location before any receipt. Check it on **Item Ledger Entries**
  filtered on **Open = Yes**.

### 3. Create the MCP configuration in Business Central

You need the **MCP - Admin** permission set.

1. Search for **Model Context Protocol (MCP) Server Configurations** and choose **New**.
2. **Name:** `InvestigationAssistant`. **Description:** Investigation Assistant agent.
3. Leave **Active** off while you configure. Turn **Unblock Edit Tools** on (needed for creating findings).
4. Under **Server Features**, activate **API Tools**. Leave **Dynamic Tool Mode** off.
5. Under **Available APIs**, add these objects with **API Version** `v1.0`:

   | Object Type | Object ID | Allow Read | Allow Create | Allow Modify | Allow Delete | Allow Actions |
   |---|---|---|---|---|---|---|
   | Query | 58001 | ✔ | | | | |
   | Query | 58002 | ✔ | | | | |
   | Page | 58004 | ✔ | | | | |
   | Page | 58005 | ✔ | | | | |
   | Page | 58006 | ✔ | | | | |
   | Page | 58007 | ✔ | ✔ | | | |

6. Choose **Validate** and fix any warnings, then turn **Active** on.
7. Choose **Advanced → Connection String** and note the **TenantId**, **EnvironmentName** and **Company**.

### 4. Register an Entra app for Foundry

Register it in the same Entra tenant as your Business Central trial.

1. **Microsoft Entra admin center → App registrations → New registration.**
   Name: `Foundry - BC Investigation Assistant`. Supported account types: **Accounts in any organizational directory (multitenant)**. Register.
2. Copy the **Application (client) ID** and **Directory (tenant) ID**.
3. **Certificates & secrets → New client secret.** Copy the secret value now; it's shown only once.
4. **API permissions → Add a permission → Dynamics 365 Business Central → Delegated permissions →
   Financials.ReadWrite.All.** Then **Grant admin consent**.
5. Leave the redirect URI for now. Foundry gives it to you in the next step.

### 5. Create the OAuth connection in Foundry

1. In the Foundry portal, open your project, go to **Build → Tools → Connect a tool → Custom → MCP**.
2. **Name:** `bc-mcp`. **Endpoint:** `https://mcp.businesscentral.dynamics.com`
3. **Authentication:** **OAuth Identity Passthrough**, with:

   | Field | Value |
   |---|---|
   | Client ID | from step 4 |
   | Client secret | from step 4 |
   | Auth URL | `https://login.microsoftonline.com/<BC tenant ID>/oauth2/v2.0/authorize` |
   | Token URL | `https://login.microsoftonline.com/<BC tenant ID>/oauth2/v2.0/token` |
   | Refresh URL | same as Token URL |
   | Scopes | `https://api.businesscentral.dynamics.com/Financials.ReadWrite.All offline_access` |

4. Save, copy the **redirect URL** Foundry shows, and add it in the Entra app under
   **Authentication → Add a platform → Web → Redirect URIs**.

### 6. Install and configure the agent

```powershell
cd agent
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
az login
copy .env.example .env
```

Fill in `.env`: the project endpoint (Foundry home page), your model deployment name, `bc-mcp`, and the
BC values from step 3. `.env` is in `.gitignore`, so it is never committed.

### 7. Create the agent and start investigating

```powershell
python create_agent.py
python chat.py
```

The first question opens a Business Central sign-in link (OAuth consent). Sign in with your BC user,
close the window, and press Enter. Then try:

- *Is anything wrong with inventory?*
- *Investigate the largest drop-ship imbalance.*
- *Why is item 1896-S negative at WEST?*
- *Record that as a finding.* → you see the exact tool call and must type `yes`.

Then open **BCIA Investigation Findings** in Business Central to review the finding.
Every approval decision is logged in `agent/approvals.log`.

---

## Points still to confirm on the first run

These come from gaps in current documentation. Each has a planned fallback.

| # | What could happen | What to do |
|---|---|---|
| 1 | Foundry blocks the token: *"Cannot pass Microsoft token to untrusted MCP endpoint"* | The Foundry-hosted route won't work yet with BC's token audience. Fall back to running the agent loop locally with your own sign-in. |
| 2 | Consent or `tools/list` fails with a 401 or audience error | The scope in step 5 is wrong for the MCP server. Try `https://api.businesscentral.dynamics.com/.default offline_access`. |
| 3 | The agent can't find the tools, or asks approval for reads | The tool names differ from the expected pattern. The approval list in `create_agent.py` fails safe (it asks instead of acting); update `READ_ONLY_TOOLS` with the real names. |
| 4 | BC says the company or environment is missing | Foundry didn't send the headers alongside OAuth. Make `InvestigationAssistant` the **default** configuration in BC and check the values in `.env`. |

## Adding a problem module

A new problem type is a small module, not a new app. For example, "items with unadjusted cost":

**In Business Central (AL):**
1. **Detection query:** an API query in `src/Modules/<Problem>/` that returns only the problem rows,
   with SQL doing the calculation (like `BCIA Negative Inventory API`).
2. **Module codeunit:** implements `BCIA Problem Module`. `AddItemChecks` adds the facts for one item
   under its own key in the Copilot evidence; `GetPromptRules` tells the model how to read them.
3. **Enum value:** add a value to `BCIA Problem Type` pointing to the module codeunit. The Copilot
   evidence, the system prompt and the findings pick it up automatically.
4. **Tests:** a test for the query and one for the module's checks. The framework test
   `EveryProblemTypeHasPromptRules` fails if you forget the prompt rules.
5. **Permission set:** add the new objects.

**For the agent:**
6. **Module instructions:** add `agent/modules/<problem>.md` with what "wrong" looks like, the tools,
   investigation steps and typical root causes. `create_agent.py` loads every file in that folder.
7. **Read-only tool:** add the query's tool name to `READ_ONLY_TOOLS` in `create_agent.py`.
8. **MCP configuration:** add the query to the BC MCP configuration with **Allow Read**.
9. Run `python create_agent.py` again to publish a new agent version.

`BCIA Problem Type` is extensible, so a module can also live in a separate app that depends on this one.

## Files

| File | Purpose |
|---|---|
| `instructions.md` | General method and rules for every problem type |
| `modules/*.md` | One section per problem module: what's wrong, tools, steps, typical root causes |
| `create_agent.py` | Combines the instructions, and creates the agent in Foundry with the BC MCP tool and approval policy |
| `chat.py` | Console chat: handles sign-in consent, approval prompts and the audit log |
| `.env.example` | Settings template |
