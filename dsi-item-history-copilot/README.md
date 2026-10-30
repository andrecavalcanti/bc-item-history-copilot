# BC Investigation Assistant (main app)

This folder holds the main AL app. See the [repository README](../README.md) for what it does,
the architecture, the problem modules, setup, tests and evaluation, and [agent/README.md](../agent/README.md)
for the Investigation Assistant agent.

## Folders

| Folder | Contents |
|---|---|
| `src/Copilot` | Copilot capability registration, AI codeunit, PromptDialog page |
| `src/ItemHistory` | Evidence builder, quantity-by-location query, Item Card extension |
| `src/Framework` | `BCIA Problem Module` interface, `BCIA Problem Type` enum, module runner |
| `src/Modules` | One folder per problem module: detection query, module codeunit, read-only APIs |
| `src/Agent` | Shared agent APIs, investigation findings, human review |
| `src/Setup` | Setup table and page (API key in IsolatedStorage) |
| `src/Permissions` | `BCIA Investigation` permission set |

All objects use the prefix **BCIA** (Business Central Investigation Assistant) and IDs 50100–50149.
The test app uses IDs 50150–50199.
