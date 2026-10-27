# Assessment

Answer each question from evidence first (code, schema, data samples, auth
setup, logs, billing). Mark each answer with its source: `code`, `data`,
`human`, or `assumed`. Anything `assumed` that drives an ADOPT or SKIP must
be confirmed with the human before building.

## A. Users and identity

A1. Who uses the bot? Count and kind (internal staff, customers, public).
A2. Is there an existing identity system (Supabase Auth, OAuth/OIDC, SSO,
    custom session tokens)? The bot must reuse it, never invent its own.
A3. Do different users see different data today? How is that enforced:
    in the database (row-level security, grants), in an API layer, or only
    in the UI (hidden tabs)? UI-only rules are not a wall; write that down.
A4. Is there any data no user may see through the bot even though they can
    see it elsewhere? (Usually no; if yes, it must be enforced below the bot.)

## B. Knowledge and data

B1. What will people ask about? Classify each source:
    - structured data (tables, metrics, transactions)
    - documents (policies, manuals, contracts, notes)
    - live systems (ticketing, HR, ERP, CRM)
B2. For documents: total size in tokens. Under roughly 20 percent of the
    model's context window after the prompt and tools, they fit in the prompt
    outright and need no retrieval.
B3. How often does each source change? Per minute, per load, per month?
B4. Are answers numeric or factual in a way people act on (money, inventory,
    compliance)? Then output verification is needed (layers.md L5).

## C. Actions

C1. Does the bot only read, or must it act (create a ticket, apply for leave,
    send a message, change a record)?
C2. For each action: who may do it, is it reversible, does it need a human
    confirmation step?

## D. Risk

D1. What is the worst thing a successful prompt injection could do, given
    the answers above? If the bot holds no credential beyond the user's own,
    the answer is usually "say something off-topic or reveal the prompt".
D2. Is there personal data (PII) in the sources that some users must not
    see? Where is it, and can it be excluded at the source instead of
    redacted at the output?
D3. Is any output public-facing, or used in legal, financial or medical
    decisions?

## E. Volume and cost

E1. Expected messages per day and peak per minute.
E2. Budget ceiling per month and per user.
E3. Latency expectation (chat UI: first token under about 2 s).

## F. Operations

F1. Which model provider(s) are available, and is a fallback provider
    required?
F2. Where does the code run (serverless, container, edge)? Can the function
    stay alive to finish a log write after streaming?
F3. Who changes the prompt over time, and how does a change get to
    production? (This decides where the eval gate goes: CI, a merge script, or
    both.)
F4. Is there a test account with realistic permissions the eval can use?

## Decision record template

Write to `docs/chatbot-architecture.md` in the target repo:

```markdown
# <Bot name> architecture

Date: YYYY-MM-DD. Assessed by: <agent/session>. Confirmed by: <human>.

## Situation
- Users: <A1> (<source>)
- Identity: <A2>; data permissions enforced in <A3>
- Knowledge: <B1 summary>; documents total <B2> tokens; change rate <B3>
- Actions: <C1>
- Worst-case injection: <D1>
- Volume: <E1>; budget <E2>
- Runtime: <F2>; change path: <F3>

## Layers
| Layer | Decision | Reason (cites the situation) | Where it lives |
| --- | --- | --- | --- |
| L1 Proxy and server-owned config | ADOPT | always | |
| L2 Identity and permissions | | | |
| L3 Persona and scope | ADOPT | always | |
| L4 Grounding | tools / retrieval / in-prompt / none | | |
| L5 Output verification | | | |
| L6 Actions (write tools) | | | |
| L7 Guardrails | | | |
| L8 Cost: caching, quotas, routing | | | |
| L9 Observability | | | |
| L10 Evals and merge gate | ADOPT | always | |

## Re-assess when
<the triggers below that apply to this bot>
```

## Re-assess when

- A new data source or document set is connected (B1, B2).
- Documents outgrow the in-prompt budget (B2): consider retrieval.
- The bot gains its first write action (C1): adds L6 and confirmation steps.
- A new user population gets access, especially external users (A1, D3).
- Permissions move from UI-only to data-level, or the reverse (A3).
- Volume grows by about 10x (E1): reconsider routing and semantic caching.
- The model or provider changes (F1): full eval run is mandatory anyway.
