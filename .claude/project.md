# Project-Specific Configuration

> Imported by `CLAUDE.md`. Safe to edit — `/sync` never touches this file.
>
> This is where team-shared, project-specific rules, deployment targets, and
> conventions live. `CLAUDE.md` is template-managed and overwritten by `/sync`,
> so anything project-specific goes here instead.
>
> For personal, un-shared overrides (your own shortcuts, local paths,
> experiments), use `CLAUDE.local.md` instead — it's gitignored.

---

## Deployment Targets (placeholder — run /setup-deployment to populate)

> ⚠ **THIS TEMPLATE REPO HAS NO ACTIVE DEPLOYMENT TARGETS.** The heading above
> is intentionally **not** the literal `## Deployment Targets` so that
> `/verify-deployment` and `session-start.sh` treat this repo as having no
> Deployment Targets and skip silently.
>
> Downstream projects run `/setup-deployment`, which replaces this placeholder
> with a real `## Deployment Targets` section (matched by the exact-match regex
> `^## Deployment Targets[[:space:]]*$`).
>
> For the routing-table schema (columns, config block, worked example), see
> `.claude/deployments/README.md` § Routing Table Schema.

A real configured project would have a section like this (indented code block
shown below — not active in this template):

        ## Deployment Targets

        > Populated by /setup-deployment. Read by /verify-deployment.
        > Delete this section to disable deployment verification for this project.

        | Service | Runbook                          | Triggers on branch | Project ID    |
        |---------|----------------------------------|--------------------|---------------|
        | Railway | .claude/deployments/railway.md   | main               | my-api-prod   |
        | Vercel  | .claude/deployments/vercel.md    | main               | acme/marketing |

        **Config:**
        - Max fix iterations: 3
        - Build timeout: 15m
        - Preferred status source: github-checks

---

## Project-Specific Rules

> Add any team-shared rules that should apply only to this project.
> Examples: tech-stack conventions, architectural constraints, domain glossary,
> external service credentials policy.

_None yet._
