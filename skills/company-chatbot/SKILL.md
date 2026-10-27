---
name: company-chatbot
description: Design, build, audit or extend a company chatbot or AI assistant (a branded assistant over company data, documents or tools). Use when asked to create a company AI assistant, add a chatbot to an app, audit an existing bot's architecture, or decide whether a bot needs RAG, tool calling, permissions, guardrails, caching, model routing, observability or evals. The agent first assesses the situation, writes a decision record that adopts or rejects each layer with a reason, then builds only what the situation needs, and never ships a prompt, tool or model change without a passing eval.
---

# Company chatbot

A company assistant is usually described as a stack you climb in order:
persona, grounding (RAG), tools, permissions, guardrails, cost controls,
observability, evals. That list is a good **checklist of concerns** and a bad
**recipe**. About half the layers are wrong for a given company, and adding
them anyway costs money, latency and new failure modes. The one layer that is
never optional is the last: **evals that gate every behavior change**. The
classic failure is a bot that was grounded, secure and observable, and then
answered "I'm ChatGPT" because someone pushed a system prompt change without
running the evals.

Your job is to decide, per layer, from the facts of this company, and to leave
a written reason for every "no" as well as every "yes".

## Workflow

1. **Assess.** Answer every question in `references/assessment.md` from the
   code, the data and the repo first. Ask the human only what you cannot learn
   (business intent, who the users are, what may never be shown to whom). One
   question at a time.
2. **Decide.** Walk `references/layers.md` layer by layer. For each layer,
   record ADOPT, SKIP or LATER with the one-sentence reason tied to an
   assessment answer. Write it to `docs/chatbot-architecture.md` in the target
   repo using the template at the end of `references/assessment.md`. This
   document is the contract the build follows and the thing the next agent
   reads.
3. **Build in this order**, only the adopted layers:
   1. Server-side proxy that owns the key, model, prompt and tool list
      (`references/patterns.md` section 1). The browser never chooses any of them.
   2. Identity and permissions before any data tool exists (section 2).
   3. Persona and scope prompt (section 3).
   4. Grounding: tools over live data, or retrieval over documents (section 4).
   5. Output verification for numbers or citations when answers carry facts
      users act on (section 5).
   6. Cost controls: prompt caching always, quotas always, routing only when
      volume justifies it (section 6).
   7. Observability: a metadata log per model call (section 7).
   8. **Evals and the merge gate** (`references/evals.md`). Not last in
      importance: it ships before the bot is exposed to users, and every later
      change goes through it.
4. **Verify** with the eval suite, against the branch's code, not the
   deployment. Write the receipt. The gate refuses merges without it.
5. **Re-assess** when a trigger in `references/assessment.md` (section
   "Re-assess when") fires: new data source, new user population, write
   actions, volume growth, new provider or model.

## Non-negotiables (every bot, every size)

For a public bot with no login, read "user" as "session" and "identity
passthrough" as "the anonymous role": the bot still holds nothing an anonymous
visitor could not read, and quotas key on session and IP. Do not add a login
just to satisfy this list.


- The model never holds a credential the user does not have. Tools run with
  the user's own session (or the user's already-authorized data), so a
  prompt injection can at most make the bot say something; it cannot reach
  data or actions the user could not reach anyway.
- The system prompt, tool definitions and model live on the server, never in
  the client request.
- Every figure or fact the bot states comes from a tool result or a retrieved
  source in the same conversation. If none does, the bot says it does not know.
- Business knowledge injected into the prompt is cleaned (one line per item,
  no control characters) and labeled as data, not instructions.
- Prompt caching on the static prefix (tools plus system prompt), unless the
  provider caches automatically or volume is too low to pay off (layers.md L8).
- Per-user quotas enforced durably (database), failing closed.
- An identity case ("who are you?", "are you ChatGPT?") and prompt-injection
  cases in the eval suite.
- A merge gate: changing the prompt, tools, model or call parameters requires
  a passing eval receipt for exactly the merged content. The model and
  provider are pinned in a listed file, and the eval harness is listed too.

## Files

- `references/assessment.md`: the questions, how to answer them, the
  decision-record template, and re-assessment triggers.
- `references/layers.md`: each layer, when it is needed, when it is harmful,
  and what to build instead.
- `references/patterns.md`: concrete, proven implementation patterns.
- `references/evals.md`: eval suite design, the receipt contract and the gate.
- `references/case-studies.md`: two production audits and what they changed.
- `templates/`: eval-gate script, JS receipt helper, GitHub Actions workflow,
  example `prompt-files.txt`.
