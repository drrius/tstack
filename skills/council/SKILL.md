---
name: council
description: Trigger this if the user says 'council'.
---

# Council

If `origin` is an Azure DevOps remote, read [azure-devops](../azure-devops/SKILL.md) first and use its translations for every `gh` step and GitHub concept below.

Before an audit, address outstanding PR comments, fix known issues, and run
relevant checks. Give council the updated implementation; do not defer known
fixes until reviews return. If the user wants to discard the implementation
and explore new ideas, skip fixes to code being replaced.

Bring in three delegates to help with the user's request, usually for review
or feedback. Use one strong model from each of three different providers, at
high reasoning effort. If the user's instructions name council members, use
those. Otherwise pick the latest flagship model from each provider, for
example Claude Opus, GPT Sol, and Grok.

Run Grok as Grok 4.7 on the `cursor` provider at high effort with fast mode
on (`reasoning_effort: high`, `fastMode: true`). Fast mode is required, and
only `cursor` offers it, so do not run Grok through another provider.

In T3 Code, use `orchestrator_capabilities` to resolve the models, then
`delegate_task` to start one delegate per model in parallel. Elsewhere, use
the harness's subagent tools. If you cannot reach three providers, or a named
member is unavailable, report it instead of substituting.

When pstack-anywhere is installed, the council is pstack's
`interrogate reviewers` role, so pstack's models file picks the members and
the provider each runs on. Save the bare `orchestrator_capabilities` payload
to a temporary catalog JSON file, then run the `check-t3.ts` that the
poteto-mode skill names:
`bun <check-t3.ts> --catalog <file> "interrogate reviewers" --job judgment`.
Start one delegate per seat and pass its `target` unchanged. If the checker
fails, report its error instead of substituting. To change the members, run
`/setup-pstack`.

Give each delegate the request and relevant context. For review or feedback,
keep their work read-only. Collect their responses and summarize the useful
findings, disagreements, and recommended next steps.

Do not wait idle. When a result arrives, check its findings against the code
at once and decide what to fix while the other delegates run. Do not edit
files while a delegate still reviews the same checkout. If the user's
instructions mark a delegate as non-blocking, do not wait for it; treat a
late result as feedback and do not record its score.

For a code review, ask each delegate for a score out of 10.
Count each full review pass as one round.
A fresh review after fixes starts a new round.

If the work ends in a pull request, put the results in the PR description.
Put this section before the model and harness line at the end:

```markdown
## Council review

Rounds: 2

| Delegate | Round 1 | Round 2 |
| --- | --- | --- |
| Claude Opus | 7/10 | 9/10 |
| GPT Sol | 8/10 | 10/10 |
| Grok | 7/10 | 9/10 |
```

If a delegate gives no score, write `no score`. Do not invent one.
If the PR is open, edit the description. Do not post a comment for this.
If there is no PR, put the same results in the final reply only.

If you agree with their recommendations, make the changes and request a fresh
review after. Continue this process until all delegates are satisfied with the
outcome.

Do not let repeated reviews result in scope creep. It is your job to fight to
keep scope limited.
