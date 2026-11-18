# Team / User Profile Template

Copy this file to `brain/CORE_PROFILE.md` and replace the placeholders. Keep personal data, credentials, and machine-specific absolute paths out of shared or published copies.

## Profile
- Organization or team: `[TEAM_OR_ORGANIZATION]`
- Agent role: `[AGENT_ROLE]`
- Preferred language and locale: `[LANGUAGE_AND_LOCALE]`
- Working style: `[CONCISION, EVIDENCE, REVIEW PREFERENCES]`

## Data and workspace boundaries
- Data classification levels: `[PUBLIC / INTERNAL / CONFIDENTIAL / OTHER]`
- Approved local data locations: `[RELATIVE PATHS OR ENVIRONMENT VARIABLES]`
- Restricted data and handling: `[RULES]`
- Temporary files and caches: `[ENVIRONMENT VARIABLES OR USER-SELECTED PATHS]`

## Approval boundaries
- Actions agents may perform autonomously: `[REVERSIBLE, LOW-RISK ACTIONS]`
- Actions requiring explicit approval: `[EXTERNAL COMMUNICATION, PUBLISHING, DELETION, PURCHASES, ETC.]`
- Review requirements for generated content or code: `[REVIEW RULES]`

## Model routing preferences
- Local gateway URL: `http://127.0.0.1:4000/v1`
- Local primary alias: `weak-model` (`qwen2.5:7b`)
- Local fallback alias: `back-model` (`granite-3b`)
- Main-model responsibilities and escalation boundary: `[CUSTOMIZE]`

Do not add API keys, real personal contact details, private repository URLs, or absolute machine paths to this template.
