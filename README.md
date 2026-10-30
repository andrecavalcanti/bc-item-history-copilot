# BC Investigation Assistant

[![CI/CD](https://github.com/andrecavalcanti/bc-item-history-copilot/actions/workflows/CICD.yaml/badge.svg)](https://github.com/andrecavalcanti/bc-item-history-copilot/actions/workflows/CICD.yaml)

An AI investigation framework for **Microsoft Dynamics 365 Business Central**, with two ways to use it:

1. **Copilot on the Item Card:** explains an item's inventory history in plain language and flags problems, such as drop-shipment entries that don't net to zero or negative inventory. Built with the Business Central **Copilot toolkit** (System.AI module) and a model in your own **Microsoft Foundry / Azure OpenAI** resource.
2. **Investigation Assistant agent:** a Foundry agent that investigates problems across all items through the **Business Central MCP server** and proposes findings that a person must approve. See [`agent/README.md`](agent/README.md).

Each problem type is a **module** (interface + extensible enum). Drop shipment and negative inventory are the first two; adding another is a small module, not a new app.

<!-- Add a screenshot: save it as docs/images/explain-dialog.png and remove this comment -->
<!-- ![Explain inventory history dialog](docs/images/explain-dialog.png) -->

---

## What it does

On the **Item Card**, the user chooses **Explain inventory history**, optionally asks a question, and chooses **Generate**. Copilot returns a short summary of recent movements, then any flags, for example:

> Drop-ship entries at location EAST total 4 instead of 0. Check the linked sales and purchase orders for a quantity received but not shipped.

The user can keep or discard the answer. Copilot never posts, changes or deletes data.

## Problem modules

| Module | Detects | Copilot evidence | Agent tools |
|---|---|---|---|
| Drop shipment | Drop-ship entries that don't net to zero per location | `checks.dropShipment` | Imbalance query, drop-ship sales and purchase lines |
| Negative inventory | Open outbound entries not covered by stock | `checks.negativeInventory` | Negative inventory query |

Every module implements the `BCIA Problem Module` interface and is registered in the extensible `BCIA Problem Type` enum. The evidence builder and the system prompt loop over all modules, so a new module is picked up without changing them.

## Design principle: AL calculates, the model explains

LLMs are good at turning evidence into a readable explanation and unreliable at arithmetic. So the work is split deliberately:

| Responsibility | Done by | Why |
|---|---|---|
| Reading ledger entries | AL (partial records, read-only query) | Fast, permission-checked, deterministic |
| Totals per item, location and drop-ship flag | AL (`CalcSums`, query with `Method = Sum`) | Numbers must be exact |
| Deciding whether older entries were left out | AL | Avoids the model guessing about missing data |
| Explaining the history and suggesting checks | Model | What LLMs do well |
| Changing data | Nobody | The feature is read-only by design |

The deterministic part is covered by automated tests; the model's part is covered by an evaluation set (see below).

## Architecture

```mermaid
flowchart LR
    U[User on Item Card] --> P[PromptDialog page]
    P --> AI[BCIA Item History AI]
    AI --> B[BCIA Item History Builder]
    B --> ILE[(Item Ledger Entry)]
    B --> Q[BCIA Item Qty By Location query]
    B --> M[Problem modules: drop shipment, negative inventory]
    B -- evidence JSON --> AI
    AI -- system prompt + evidence --> AOAI[Azure OpenAI deployment in Foundry]
    AOAI -- explanation --> AI
    AI --> P
    AI -. system metadata only .-> T[Application Insights telemetry]
```

1. `BCIA Item History Builder` collects the most recent entries (newest first, configurable limit) and pre-calculated totals into a JSON document, and adds each problem module's checks under `checks`.
2. `BCIA Item History AI` sends a system prompt with strict rules, including one rule per problem module, plus the evidence wrapped in `<data>` tags to the model through the `Azure OpenAI` codeunit.
3. The answer is shown in a `PromptDialog` page. Telemetry logs success and duration only, never item numbers, prompts or answers.

## Repository structure

```
dsi-item-history-copilot/        Main app
  src/Copilot/                   Capability registration, AI codeunit, PromptDialog
  src/ItemHistory/               Evidence builder, query, Item Card extension
  src/Framework/                 Problem module interface, problem type enum, module runner
  src/Modules/DropShipment/      Drop shipment module, detection query, read-only APIs
  src/Modules/NegativeInventory/ Negative inventory module, detection query
  src/Agent/                     Shared agent APIs, investigation findings, human review
  src/Setup/                     Setup table and page (API key in IsolatedStorage)
  src/Permissions/               Permission set
dsi-item-history-copilot-test/   Test app (AL Test Tool)
agent/                           Foundry agent: instructions, problem modules, create and chat scripts
.AL-Go/ .github/                 AL-Go for GitHub build, test and release pipelines
```

## Setup

**Requirements:** Business Central 27 or later (online, or a container for development), and an Azure subscription.

1. In **Microsoft Foundry**, create a project and deploy a chat model. Note the endpoint (`https://<resource>.openai.azure.com/`), deployment name and API key.
2. Install the app from the [latest release](https://github.com/andrecavalcanti/bc-item-history-copilot/releases/latest), or publish it from VS Code.
3. In Business Central, open **Copilot & agent capabilities** and make sure **Explain item inventory history** is active.
4. Open **BCIA Copilot Setup**, enter the endpoint, deployment name and API key, and choose **Test Connection**.
5. Assign the **BCIA Investigation** permission set to users.

The capability is registered as **Preview** with billing type **Custom Billed**, because it uses your own Azure OpenAI resource.

## Tests

The test app runs on every push through AL-Go for GitHub. It tests the evidence builder only, so the tests are fast, free and repeatable, with no calls to Azure OpenAI.

| Test | Checks |
|---|---|
| `NoEntriesReturnsZeroTotals` | An item without entries returns zero totals |
| `NormalEntriesOnlyHaveZeroDropShipTotal` | Normal movements are totalled; drop-ship total stays 0 |
| `BalancedDropShipmentNetsToZero` | A standard drop shipment nets to zero |
| `UnbalancedDropShipmentIsReportedPerLocation` | An imbalance is reported at the right location |
| `EntryLimitMarksOlderEntriesOmitted` | Only the limit is sent; totals still cover all entries |
| `EntryCountEqualToLimitIsNotFlaggedAsOmitted` | Exactly the limit is not flagged as incomplete |
| `MostRecentEntryComesFirst` | The limit keeps the newest history |
| `ZeroLimitFallsBackToDefault` | A missing limit falls back to 50 |
| `PostedItemJournalIsIncludedInTotals` | Real posting is picked up correctly |

Two more test codeunits cover the framework and the agent:

| Codeunit | Checks |
|---|---|
| `BCIA Problem Module Test` (6 tests) | Every problem type has prompt rules; the evidence and prompt include every module; each module reports exactly the right locations and quantities; a healthy item raises no flags |
| `BCIA Investigation Agent Test` (8 tests) | The agent's detection queries return only real problems; findings must name a problem type and always start as New; review decisions can't be overwritten or skipped |

Writing these tests found a bug: an item with exactly the entry limit was reported as having older entries left out. It is fixed in the builder and covered by `EntryCountEqualToLimitIsNotFlaggedAsOmitted`.

## Evaluation

Model output is not deterministic, so it is checked against a fixed set of items with known histories, rerun after every prompt or model change. All data is synthetic (CRONUS demo company).

<!-- Fill in after each eval run -->

| # | Scenario | Expected answer | Correct? | Notes |
|---|---|---|---|---|
| 1 | Normal stock item | Summary, no flags | | |
| 2 | Balanced drop shipment | No drop-ship flag | | |
| 3 | Unbalanced drop shipment | Flags the location with the imbalance | | |
| 4 | More entries than the limit | Mentions older entries are not included | | |
| 5 | Item without entries | Says there is no history | | |
| 6 | User question about a specific location | Answers from that location's totals only | | |

**Model:** _deployment and version_ · **Last run:** _date_ · **Score:** _x / 6_

## Responsible AI and security

- **Read-only:** the model can only explain. The prompt forbids suggesting posting, deleting or modifying entries, and the code has no write path.
- **Human in the loop:** the user reviews every answer and chooses to keep or discard it.
- **Admin control:** the capability can be switched off on the Copilot & agent capabilities page.
- **Prompt injection:** evidence is passed inside `<data>` tags with an instruction to treat it as data. This reduces risk but is not a guarantee, which is why the feature has no write access.
- **Secrets:** the API key is stored in IsolatedStorage, never in tables or source code.
- **Data minimization:** only the fields needed for the explanation are sent, up to a configurable number of entries.
- **Telemetry:** system metadata only (success, duration).

## Roadmap

- [ ] HttpClient-mocked tests for error handling in the AI codeunit
- [ ] Structured JSON output with a confidence level
- [ ] Automated eval script that scores answers against the expected results
- [x] Foundry agent that investigates problems through the Business Central MCP server, with human approval before any write
- [x] Problem module framework (interface + extensible enum): drop shipment, negative inventory
- [ ] More modules: unadjusted cost, warehouse vs. inventory mismatch, stock stuck in transit
- [ ] Document archives in the drop-shipment evidence, to trace changed links

## Tech stack

AL · Business Central Copilot toolkit (System.AI) · Business Central MCP server · Microsoft Foundry / Azure OpenAI · Foundry Agent Service (Python) · AL Test Tool · AL-Go for GitHub · Application Insights
