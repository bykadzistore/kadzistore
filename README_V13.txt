KADZI STORE V13 — NOTIFICATIONS + UNIVERSAL IOS CERTIFICATE

Files changed:
- index.html — notification bell, separate notification center, scroll pagination, custom certificate dropdown, universal certificate picker and catalog filters.
- admin.html — Certificates option in the product category selector.
- migrations/kds_v13_ios_certificate_bundle_and_catalog.sql — database migration (already applied to Supabase).
- CHANGELOG_V13.txt — change summary.
- BACKEND_CHANGES_V13.txt — Supabase deployment notes.

GitHub commit:
- Replace index.html.
- Replace admin.html.
- Add migrations/kds_v13_ios_certificate_bundle_and_catalog.sql.
- Add the V13 changelog and backend notes if you keep documentation in the repository.

Supabase:
- Migration already applied. Do not run it a second time.
- Edge Function kds-api-v9 already deployed as version 7.
- Edge Function kds-admin already deployed as version 32.
- Do not redeploy either function from this ZIP.
- The existing iOS Certificate product was updated in the database; no duplicate product was created.

Never commit .env files, service-role keys, bot tokens, passwords, or other secrets.
