KADZI STORE V10 — audit maintenance release

Start from the existing V9 deployment. This is an incremental update, not a rebuild.

Files to replace in the static GitHub Pages root:
- index.html
- admin.html (kept functionally compatible; existing file retained)

The migrations folder retains the V9 SQL already applied to the connected Supabase project. The V10 backend hardening and Edge Function updates have already been applied directly to Supabase; see BACKEND_CHANGES_V10.txt. Do not re-run the V9 migrations if they are already recorded in Supabase migration history.

Currency behavior: RUB is the accounting and settlement currency. USDT is an approximate display conversion based on a current Tether/RUB market quote. Wallet debits, top-up requests, stored product prices, orders and analytics remain RUB.
