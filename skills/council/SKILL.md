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
example Claude Opus, GPT Sol, and Gemini 4 Neon.

Run Gemini as Gemini 4 Neon (`gemini-4-neon`) on the `antigravity` provider at
high thought level (`thought_level: high`). Do not run it through another
provider.

In T3 Code, use `orchestrator_capabilities` to resolve the models, then
`delegate_task` to start one delegate per model in parallel. Elsewhere, use
the harness's subagent tools. If you cannot reach three providers, or a named
member is unavailable, report it instead of substituting.

When pstack-anywhere is installed, the council is pstack's
`interrogate reviewers` role, so pstack's models file picks the members and
the provider each runs on, and this replaces the latest-flagship rule above.
pstack is installed when a `poteto-mode` skill sits beside this one. Read its
`SKILL.md`: step 2 gives the absolute path of `check-t3.ts`. Do not search
for the checker or the models file; skill folders are symlinks, so `find`
misses them. Save the bare `orchestrator_capabilities` payload to a temporary
catalog JSON file, then run
`bun <check-t3.ts> --catalog <file> "interrogate reviewers" --job judgment`.
Start one delegate per seat and pass its `target` unchanged. If you cannot
run the checker or it fails, report that and stop instead of picking models
yourself. To change the members, run `/setup-pstack`.

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

Put the results in the final reply only. Do not add them to the PR description
or post them as a PR comment.

```markdown
## Council review

Rounds: 2

| Delegate | Round 1 | Round 2 |
| --- | --- | --- |
| Claude Opus | 7/10 | 9/10 |
| GPT Sol | 8/10 | 10/10 |
| Gemini 4 Neon | 7/10 | 9/10 |
```

If a delegate gives no score, write `no score`. Do not invent one.

If you agree with their recommendations, make the changes and request a fresh
review after. Continue this process until all delegates are satisfied with the
outcome.

Do not let repeated reviews result in scope creep. It is your job to fight to
keep scope limited.
