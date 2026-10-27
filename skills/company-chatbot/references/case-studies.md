# Case studies

Two internal assistants at a mid-size producer, audited against
the common "build your own company AI" stack. About a dozen internal users
each; one company identity system per app; data is structured (commercial
figures, operational measurements), plus a small set of business definitions or approved facts.

## Assistant A: commercial analytics

Situation: commercial figures in Postgres with row-level security tied to an
allowlist; a dozen users; answers are money figures people act on; no write
actions; serverless runtime.

| Layer | Decision | Why |
| --- | --- | --- |
| Persona and scope | had it | |
| RAG | SKIP | definitions are under 12 KB and go in the prompt whole; numbers come from query tools, which beat retrieved text for totals |
| Tools | had it | read-only tools executed in the browser with the user's session; one parameterized database function for arbitrary cross-tabs |
| Permissions | had it | identity passthrough; database decides. Noted: UI roles hide tabs only, so they do not restrict the bot either |
| Guardrails | prompt rules plus hard output verification; no classifiers | the bot holds no capability beyond the user's; the dangerous failure is a wrong number, so every figure is verified mechanically |
| Cost | had caching and durable quotas; SKIP routing and semantic caching | volume is tiny; cached answers would go stale on each data load |
| Observability | GAP, then ADOPTED | only a usage counter existed; added a metadata-only per-call log (privacy decision by the owner: no question text) |
| Evals | GAP, then ADOPTED | a grounding eval existed but ran by hand against the deployment, with no identity case; made it run on the branch, added identity and injection cases, and put a receipt gate on merges |

Review findings during the log build, all fixed: tool names and stop reasons
needed closed lists in the database too (a user could call the logging
function by hand with prose shaped like identifiers); a count-then-insert cap
needed a per-user lock; a provider error event was being recorded as
"other"; a logging call that returned "not inserted" counted as success.

## Assistant B: operations analytics

Situation: operational data already loaded in the user's browser; staff can approve
"facts" the bot proposes; same scale.

| Layer | Decision | Why |
| --- | --- | --- |
| Tools and permissions | had it | tools run over data already in the user's browser |
| Knowledge | had it, HARDENED | approved facts were injected without stripping line breaks or labeling them as data, so one approved fact could add rules; now one line each and labeled non-instructive |
| Cost | GAP, then ADOPTED | no prompt caching; added one breakpoint on the last system block |
| Observability | had it | conversations are persisted per user |
| Evals | GAP, then ADOPTED (in progress at audit time) | no behavior eval at all; being built with identity, scope, grounding and injection cases plus the receipt |

## Lessons

- The stack in the viral version is a list of concerns, not a recipe. Half
  the layers were correctly absent here.
- Identity passthrough made most guardrail layers unnecessary.
- The real gaps were the cheap, boring ones: caching, a log, and an eval that
  actually gates changes.
- Same-vendor review approved things a cross-vendor review then blocked;
  use an independent reviewer for the gate and anything touching data.
