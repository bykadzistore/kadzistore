KADZI STORE V11 — Financial analytics / audit

Replace admin.html in the GitHub Pages root. index.html is unchanged. Supabase migration kds_purchase_cost_and_order_cost_snapshot was applied; kds-admin Edge Function deployed as version 31.

Admin tariff format: Duration label | days | retail price RUB | purchase price RUB | on/off
Example: 1 day | 1 | 250 | 210 | on

New orders snapshot the cost. Historical orders remain unverified if their cost was not stored.

Analytics assumes the 1% payment fee is deducted from KADZI revenue. Withdrawal fee is 0%; server is free. If 1% is charged on top to the buyer, the merchant-side payment fee should be set to 0%.
