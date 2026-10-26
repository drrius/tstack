# tstack

The agent skills I use every day, cleaned up so anyone can use them. They work
in Claude Code and Codex. Some use [T3 Code](https://github.com/pingdotgg/t3code)
features when they are available and fall back to native tools when they are
not.

This is [drrius](https://github.com/drrius)'s fork of
[t3dotgg/tstack](https://github.com/t3dotgg/tstack). It adds Azure DevOps
support, so the same skills run against GitHub and Azure Repos, and an
installer that symlinks the skills instead of copying them. All credit for the
skills goes to Theo Browne.

## Skills

| Skill | Say | What it does |
|---|---|---|
| `full-send` | "full send" | Takes a change to a merged PR with nobody watching: proves it, reviews it, files it, babysits it, merges it. |
| `full-stop` | "full stop" | Same as `full-send`, but stops when the PR is ready for you to merge. |
| `council` | "council" | Gets review from three models from different providers, and loops until they agree. |
| `sol-loop` | "sol loop" | Reviews a change with GPT Sol in a loop until both agents agree. |
| `file-pr` | "file a PR" | Files a short PR that leads with the problem, not an inventory of changes. |
| `takeover` | "take over" | Finishes someone else's PR, branch, or agent thread, and keeps their credit. |
| `babysit-pr` | "babysit" | Watches a PR through CI and review bots, and fixes the real findings. |
| `modernize` | "modernize" | Rebases an old PR and decides if it should still exist. |
| `leaving-pr-comments` | (automatic) | Formats comments that an agent posts on your behalf. |
| `azure-devops` | (automatic) | Translates every `gh` step and GitHub concept in the other skills to the Azure CLI when `origin` is an Azure DevOps remote. |

Some skills call others. Install the ones they need too:

- `full-send` uses `sol-loop`, `file-pr`, and `babysit-pr`.
- `full-stop` uses `full-send`.
- `takeover` uses `modernize`, `file-pr`, `babysit-pr`, and `leaving-pr-comments`.
- `file-pr`, `babysit-pr`, and `modernize` use `leaving-pr-comments`.
- Every skill that touches a PR reads `azure-devops` when the remote is Azure DevOps.

## Install

```bash
git clone https://github.com/drrius/tstack
cd tstack
./install.sh
```

The installer symlinks each skill into `~/.claude/skills/` (Claude Code) and
`~/.codex/skills/` (Codex), so edits in this checkout take effect at once. It
skips a name another skill already uses and says so. `./install.sh --force`
takes those names over and moves the old entries to
`~/.local/state/tstack/backup/`. `./uninstall.sh` removes only the links this
repo made. Rerun `./install.sh` after pulling.

To copy instead, as upstream does:

```bash
cp -R tstack/skills/* ~/.claude/skills/   # Claude Code
cp -R tstack/skills/* ~/.codex/skills/    # Codex
```

## Requirements

- On GitHub remotes, an authenticated [GitHub CLI](https://cli.github.com) (`gh`).
- On Azure DevOps remotes, the [Azure CLI](https://learn.microsoft.com/cli/azure/)
  with its `azure-devops` extension, signed in with `az login` or
  `az devops login`. The extension installs itself the first time you run
  `az repos`.
- `python3` for `babysit-pr`'s `pr-wait` (GitHub) and `pr-wait-ado` (Azure
  DevOps) scripts.
- `council` and `sol-loop` need subagents on other providers' models. T3 Code
  does this with `delegate_task`. Otherwise you need a harness that can run
  those models.

## GitHub and Azure DevOps

The skills are written for GitHub. Each PR skill starts with one line: if
`origin` is an Azure DevOps remote, read `azure-devops` first. That skill is a
translation table from each `gh` command and GitHub concept (checks, merge
state, review threads, auto-merge, alerts in comments) to `az repos`,
`az devops invoke`, and the Azure DevOps policy model. The rules in the skills
do not change. Only the commands do.

`babysit-pr` waits with `pr-wait` on GitHub and `pr-wait-ado` on Azure DevOps.
They take the same arguments and exit with the same codes. On Azure DevOps,
`ready` means every blocking policy passed except reviewer policies, the merge
succeeded, and no thread is open. Human approval stays your call.

`pr-wait-ado` was written against Microsoft's CLI and REST documentation, not
a live organization. If a call is rejected, the `azure-devops` skill says how
to find the right resource name.

## Make them yours

These are starting points. Edit them. Put personal settings, like which models
sit on your council, in your `CLAUDE.md` or `AGENTS.md`, so you can update the
skills without losing them.

## Update from upstream

```bash
git fetch upstream
git merge upstream/main
./install.sh
```

`upstream` is `https://github.com/t3dotgg/tstack`. This fork adds one line at
the top of each PR skill and keeps the rest as upstream wrote it, so merges
stay small.

## License

[MIT](LICENSE)
