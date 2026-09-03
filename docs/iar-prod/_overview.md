# iar-prod Overview

## What iar-prod Is

SecPlatform -- a multi-tenant SaaS PoC for vulnerability management and asset scanning. Frontend for the i.ar SaaS idea. Originally developed by a friend on their infrastructure (SL437, dellasantina.com.ar), now adapted to run on our infra.

Repo at `/var/home/nacho/repos/iar-prod/` (bind-mounted into i.ar container). GitHub: `github.com/randazzo-ignacio/i.ar` (shared with the i.ar repo name).

## Hosting (summary)

Prod on sophon (10.66.0.5, podman compose); Caddy on rammstein (10.66.0.1) terminates TLS over WireGuard. Domains: app.i.ar (:8091), app-bo.i.ar (:8092), auth.i.ar (:8080). Full detail: deployment.md (Caddy config, port map, DNS).

## Architecture

```
Frontends (Nginx)     frontend-client :8091    frontend-backoffice :8092
       |                    |                           |
       v                    v                           v
BFFs (Node.js/Express) bff-client :3001     bff-backoffice :3002
       |                    |                           |
       +---- OIDC ----> Keycloak :8080 <----+------+
       |                    |                     |
       v                    v                     v
  Postgres BFF :5432    Postgres KC (internal)   MailHog (disabled in prod MVP)
  (control-plane +     (Keycloak DB)
   tenant DBs)
       |
       v
  Scanner Worker (background, filesystem-based job queue)
```

## Services (docker-compose.yml)

| Service | Image | Purpose |
|---------|-------|---------|
| postgres-keycloak | postgres:16-alpine | Keycloak internal DB |
| keycloak | quay.io/keycloak/keycloak:26.7.0 | Identity Provider (OIDC) |
| postgres-bff | postgres:16-alpine | Control-plane DB + per-tenant DBs |
| bff-client | Build local (Node 20) | API for customer portal |
| bff-backoffice | Build local (Node 20) | API for back-office |
| frontend-client | Build local (Nginx) | SPA customer portal |
| frontend-backoffice | Build local (Nginx) | SPA back-office |
| scanner-worker | Build local (Node 20) | Background scan worker |
| mailhog | mailhog/mailhog:latest | SMTP testing (dev only, disabled in prod MVP) |

## Multi-Tenant Model (summary)

Physical DB per tenant (`tenant_<tid>` + own role), control-plane DB (`bff_control_plane`: tenants registry, audit_log, user_invites), filesystem isolation per tenant (`/tenants/<tid>/`), JWT `tenant_ids` validated against `X-Active-Tenant` header (fail-closed 403). Full detail: architecture.md (data model), security.md (tenant isolation).

## Keycloak Realms (summary)

`customers` (tenant users; roles: tenant-owner, asset-operator, asset-auditor, vulnerability-manager, report-viewer) and `backoffice` (staff; owner-backoffice, organization-provisioner, triage-lead, triage-analyst, billing-manager, support-readonly). JWT claims: `tenant_ids` (multivalued, customers only), `roles`, `scope_type` (`tenant`/`backoffice`). Redirect URIs: `https://app.i.ar/api/auth/callback`, `https://app-bo.i.ar/api/auth/callback`. RBAC detail: security.md.

## MVP Status

No email (invite/reset fail silently; users created manually in KC admin), no MFA, no CI/CD (manual Ansible deploy), no Cloudflare. Seed tenants acme+globex: deployment.md (Postgres init), modules.md (seed()).

## Full Docs

architecture.md (services, data model), security.md (tenant isolation, RBAC, audit), api.md (BFF endpoints), deployment.md (compose, Ansible, environments, hosting), modules.md (shared library, services).