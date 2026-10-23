# DSI Item History Copilot

Adds an **Explain inventory history** Copilot action to the Item Card.
AL collects recent item ledger entries and calculates all totals; your own
Azure OpenAI / Foundry deployment only explains them in plain language.

## Objects

| ID | Type | Name | Purpose |
|---|---|---|---|
| 50100 | EnumExtension | DSI Copilot Capability | Registers the capability value |
| 50100 | Codeunit | DSI Install | Registers the capability on install |
| 50101 | Codeunit | DSI Upgrade | Registers the capability on upgrade |
| 50104 | Codeunit | DSI Capability Registration | Shared registration logic |
| 50100 | Table | DSI Copilot Setup | Endpoint, deployment, entry limit (key in IsolatedStorage) |
| 50100 | Page | DSI Copilot Setup | Setup card with Test Connection |
| 50100 | Query | DSI Item Qty By Location | Set-based totals per location / drop-ship flag |
| 50102 | Codeunit | DSI Item History Builder | Deterministic evidence JSON (test this) |
| 50103 | Codeunit | DSI Item History AI | Calls the model, telemetry |
| 50103 | Page | DSI Explain Item History | PromptDialog |
| 50100 | PageExtension | DSI Item Card | Adds the Copilot action |
| 50100 | PermissionSet | DSI Item Hist Copilot | Assign to users |

## Setup

1. Open the folder in VS Code, set `environmentName` in `.vscode/launch.json`
   to your sandbox, then run **AL: Download symbols**.
2. If your sandbox is newer, you can raise `application`, `platform` and
   `runtime` in `app.json`. The values given (26.0 / 15.0) are the minimum.
3. Publish (F5).
4. Search for **Copilot & agent capabilities** and make sure
   *Explain item inventory history* is active (it is registered as Preview).
5. Open **DSI Copilot Setup** and enter:
   - Endpoint: `https://<resource>.openai.azure.com/` (path is trimmed automatically)
   - Deployment name from Foundry
   - API key
6. Choose **Test Connection**.
7. Assign the **DSI Item Hist Copilot** permission set.
8. Open an item → **Explain inventory history** → **Generate**.

## Troubleshooting

- **"Unsupported parameter / value: temperature or max_tokens"**: the code sends no
  sampling parameters, so this should not happen. If you add them back, GPT-5 family
  (reasoning) models will reject them.
- **Capability not active / not listed**: reinstall the app (the install codeunit
  registers it) or check the Copilot & agent capabilities page.
- **Data movement error**: your Azure resource is in a different geography than the
  BC environment. An admin must allow data movement on the Copilot & agent
  capabilities page, or use a resource in the same geography.
- **Page "Copilot AI Capabilities" not found** when compiling: remove the
  `CopilotCapabilities` action from the setup page; it is only a shortcut.

## Next steps

- Add a test app that posts item journal and drop-ship entries with the standard
  test libraries and asserts the totals in `BuildEvidence`.
- Keep 5–10 items with known histories as a manual eval set and rerun after every
  prompt change.
