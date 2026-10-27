# company-chatbot-skill

A Claude Code skill for designing, building and auditing a company chatbot.
The agent assesses the company's situation first (users, identity, data,
actions, risk, volume, change path), writes a decision record that adopts or
rejects each layer of the usual "company AI" stack with a reason, builds only
what is needed, and never ships a prompt, tool or model change without a
passing eval.

- `skills/company-chatbot/SKILL.md`: entry point and workflow.
- `skills/company-chatbot/references/`: assessment, layer decisions, patterns,
  evals and the merge gate, case studies.
- `skills/company-chatbot/templates/`: `eval-gate.sh` (merge gate),
  `eval-receipt.mjs` (receipt writer for a JS eval), `github-eval-gate.yml`
  (CI gate), `prompt-files.example.txt`.
- `tests/contract.test.sh`: the bash one-liner, the JS helper and the gate
  agree on the receipt hash across edge cases.

## Install

Personal: `ln -s "$PWD/skills/company-chatbot" ~/.claude/skills/company-chatbot`
Per project: copy `skills/company-chatbot` into the project's `.claude/skills/`.

## Test

`bash tests/contract.test.sh` (needs git 2.38+, node 18+, sha256sum, jq).
