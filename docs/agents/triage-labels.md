# Triage Labels

The engineering skills use five canonical workflow roles. This repository keeps
its existing lightweight GitHub vocabulary rather than creating duplicate
labels.

| Skill role | Repository behavior | Meaning |
| --- | --- | --- |
| `needs-triage` | No workflow label | Maintainer has not evaluated the issue yet |
| `needs-info` | `question` | Waiting for clarification or reporter input |
| `ready-for-agent` | `ready-for-agent` | Fully specified and safe for an AFK agent |
| `ready-for-human` | `help wanted` | Requires human input or implementation |
| `wontfix` | `wontfix` | Will not be actioned |

Use `bug` or `enhancement` separately to classify the work itself. When a skill
mentions a workflow role, apply the corresponding behavior from this table.
