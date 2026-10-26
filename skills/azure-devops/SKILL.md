---
name: azure-devops
description: Use when the repository's origin remote is on Azure DevOps (dev.azure.com or visualstudio.com) and a skill names a gh command, a GitHub pull request concept, or watch_pull_request. Translates each to the Azure CLI.
---

# Azure DevOps

The other skills are written for GitHub and `gh`. When `git remote get-url origin`
points at `dev.azure.com`, `ssh.dev.azure.com`, or `*.visualstudio.com`, every
GitHub step in them becomes the Azure DevOps step from this file. The rules do
not change. Only the commands do. On a GitHub remote, ignore this file.

## Setup

- `az` with the `azure-devops` extension. Sign in with `az login`, or
  `az devops login` with a personal access token (also read from
  `AZURE_DEVOPS_EXT_PAT`).
- Run `az` from inside the checkout. The extension reads the organization,
  project, and repository from `origin` (`--detect`, the default). Pass
  `--org`, `--project`, and `--repository` only from another directory.
- Remote shapes: `https://dev.azure.com/<org>/<project>/_git/<repo>`,
  `https://<org>@dev.azure.com/<org>/<project>/_git/<repo>`,
  `https://<org>.visualstudio.com/<project>/_git/<repo>`, and
  `git@ssh.dev.azure.com:v3/<org>/<project>/<repo>`.
- PR URL: `https://dev.azure.com/<org>/<project>/_git/<repo>/pullrequest/<id>`.
- Default branch: `az repos show --repository <repo> --query defaultBranch -o tsv`
  prints `refs/heads/main`. `az repos pr` takes short branch names. API fields
  (`sourceRefName`, `targetRefName`) carry the `refs/heads/` prefix.
- Repository id, needed by `az devops invoke`:
  `az repos show --repository <repo> --query id -o tsv`.
- Read JSON with `-o json` and `--query <JMESPath>`. Never parse table output.

## Translations

| GitHub | Azure DevOps |
|---|---|
| `gh pr view <n> --json ...` | `az repos pr show --id <n>`. Fields: `status` (`active`, `completed`, `abandoned`), `isDraft`, `sourceRefName`, `targetRefName`, `mergeStatus` (`succeeded`, `conflicts`, `queued`, `failure`, `rejectedByPolicy`, `notSet`), `lastMergeSourceCommit.commitId` (the PR head), `lastMergeTargetCommit.commitId` (the target tip the last merge used), `reviewers[].vote`, `autoCompleteSetBy`, `createdBy`, `repository.id`. |
| `gh pr view <n> --json baseRefName,headRefOid` | `az repos pr show --id <n> --query "{base:targetRefName,head:lastMergeSourceCommit.commitId}"`, then drop `refs/heads/` from `base`. |
| `gh pr list --head <b>` | `az repos pr list --source-branch <b> --status active` |
| `gh pr create --title --body --base --head` | `az repos pr create --source-branch <b> --target-branch <base> --title "<t>" --description "$(cat body.md)"`. Each argument to `--description` is one line, and one argument with embedded newlines is kept as is. PRs open ready unless `--draft true`. If the target has a work item linking policy, pass `--work-items <id>` when the user gave one, otherwise report the blocker. |
| `gh pr edit --title --body` | `az repos pr update --id <n> --title "<t>" --description "$(cat body.md)"` |
| `gh pr ready` | `az repos pr update --id <n> --draft false` |
| `gh pr checkout <n>` | `az repos pr checkout --id <n>` |
| `gh pr checks` | `az repos pr policy list --id <n>`. Each record has `configuration.type.displayName` (`Build`, `Status`, `Minimum number of reviewers`, `Required reviewers`, `Comment requirements`, `Work item linking`, ...), `configuration.isBlocking`, `status` (`queued`, `running`, `approved`, `rejected`, `notApplicable`, `broken`), `evaluationId`, and for builds `context.buildId`. |
| rerun a failed check | `az repos pr policy queue --id <n> --evaluation-id <e>`, build policies only. One rerun, as babysit-pr says. |
| build logs | `az pipelines runs show --id <buildId>` for result and web link. The run page is `https://dev.azure.com/<org>/<project>/_build/results?buildId=<buildId>`. |
| CI not behind a policy | `az pipelines runs list --branch refs/pull/<n>/merge --top 10` |
| review threads | `az devops invoke --area git --resource pullRequestThreads --route-parameters project=<project> repositoryId=<repoId> pullRequestId=<n> --api-version 7.1 -o json`. Skip comments with `commentType` `system` and anything `isDeleted`. A thread is open when `status` is `active` or `pending`, and resolved when `fixed`, `wontFix`, `closed`, or `byDesign`. |
| reply on a thread | `az devops invoke --area git --resource pullRequestThreadComments --route-parameters project=<project> repositoryId=<repoId> pullRequestId=<n> threadId=<t> --http-method POST --in-file reply.json --api-version 7.1`, where `reply.json` is `{"content": "...", "parentCommentId": 1, "commentType": "text"}`. Write the body to the file. Never put comment text in a shell command. |
| resolve or dismiss a thread | PATCH `pullRequestThreads` with `threadId=<t>` and `{"status": "fixed"}`, or `"wontFix"` for a dismissal with a written reason. |
| new top-level comment | POST `pullRequestThreads` with `{"comments": [{"parentCommentId": 0, "content": "...", "commentType": "text"}], "status": "active"}` |
| reviews, approvals | `az repos pr reviewer list --id <n>`. `vote` is 10 approved, 5 approved with suggestions, 0 none, -5 waiting for author, -10 rejected. `isRequired` marks a required reviewer. A -5 or -10 vote is a human review requesting changes. |
| `gh pr merge --squash` | `az repos pr update --id <n> --status completed --squash true --delete-source-branch true --merge-commit-message "<title>"`. Match the strategy the repo uses: check recent completed PRs and `az repos policy list --branch <target> --repository-id <repoId>` for a merge strategy policy. |
| `gh pr merge --auto` | `az repos pr update --id <n> --auto-complete true --squash true --delete-source-branch true`. Auto-complete fires when every blocking policy passes. Confirm `autoCompleteSetBy` is set, then stay until `status` is `completed`. |
| `--admin` or any bypass | `--bypass-policy`. Never use it. |
| close a PR | `az repos pr update --id <n> --status abandoned`, only when authorized. |
| retarget a PR | `az repos pr update` has no target flag. PATCH the PR: `az devops invoke --area git --resource pullRequests --route-parameters project=<project> repositoryId=<repoId> pullRequestId=<n> --http-method PATCH --in-file retarget.json --api-version 7.1` with `{"targetRefName": "refs/heads/<b>"}`. |
| `mergeStateStatus` `DIRTY` | `mergeStatus` `conflicts`. Rebase and push with `--force-with-lease`. |
| `mergeStateStatus` `BEHIND` | No such state. Azure DevOps merges the source into the target on every push to either side, and builds run on that merge commit, which `az repos pr show` reports as `lastMergeCommit.commitId`. A build policy can be set to never expire, so an `approved` status does not prove the build saw the current target. Before completing, take the build policy's `context.buildId` from `az repos pr policy list`, then `az pipelines runs show --id <buildId> --query sourceVersion -o tsv`. If it differs from `lastMergeCommit.commitId`, the green build ran on an older merge: `az repos pr policy queue --id <n> --evaluation-id <e>` and wait for it. Hold the same rule as on GitHub: never complete when commits that landed after the last green build touch this PR's files. |
| the merge gate | Every `isBlocking` policy `approved` or `notApplicable`. `mergeStatus` `succeeded`. `isDraft` false. No required reviewer at -5 or -10. No open thread when a comment requirements policy exists. Every approved build's `sourceVersion` equals `lastMergeCommit.commitId`. |
| GitHub review bots | Greptile and Macroscope do not run on Azure DevOps. CodeRabbit does when installed, and posts threads as a service identity. Treat its findings like any other. Nothing waits for a bot. |
| `watch_pull_request` in T3 Code | Call it once with the PR URL. If T3 Code rejects the URL or cannot read the PR, use `pr-wait-ado` instead, and skip `unwatch_pull_request` at handoff. |
| `pr-wait` | `pr-wait-ado`, next to it in babysit-pr's `scripts/`. Same arguments, events, and exit codes: `pr-wait-ado <pr> [--repo <org>/<project>/<repo>] [--until ready\|green\|any-change]`. `ready` means every blocking policy passed except reviewer policies, every approved build ran on the current merge commit, the merge succeeded, and no thread is open. Human approval is the user's line, so `ready` reports pending reviewer policies instead of waiting on them, and exits 1 on a reviewer rejection or a stale build so you can act. Run it from the checkout so it can tell which target branch commits touch this PR's files. |
| `gh api rate_limit` | None. Azure DevOps throttles per user and answers 429 or a message about the request being delayed or blocked. `pr-wait-ado` backs off on its own. Never run two watchers on one PR. |
| GraphQL fallback to REST | Not needed. |
| `> [!NOTE]` in a comment | Azure DevOps does not render GitHub alerts. Start the comment with `> 🤖 **<model> responding on behalf of <user>**`, then a blank line, then the comment. Keep every other rule from leaving-pr-comments. |
| search merged or open PRs | `az repos pr list --status completed --target-branch <base> --top 50` and `az repos pr list --status active --target-branch <base>` |
| link the original PR | Its `pullrequest/<id>` URL. Azure DevOps keeps Git authorship and co-author trailers the same way, so takeover's credit rules apply unchanged. |
| stacked PRs | Set `--target-branch` to the lower branch. After the lower one completes, retarget the upper one with the PATCH above. |

## When a call is rejected

`az devops invoke` resolves `--area` and `--resource` against the organization's
API table. If it rejects a resource name, list the right one and retry:

```bash
az devops invoke --query "[?area=='git' && contains(resourceName,'pullRequest')].{resource:resourceName,route:routeTemplate}" -o json
```

If `az` says the organization or project could not be detected, you are not in
the checkout. Pass `--org https://dev.azure.com/<org>` and `--project <project>`.
