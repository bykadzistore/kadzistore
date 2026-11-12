KADZI STORE - RELEASE PACKAGE

Files:
- index.html: updated Mini App storefront, category/product cards, top-up method selection (SBP/Crypto), neutral top-up notice without a cashier brand.
- admin.html: admin panel with product-card editor and new inventory section. Inventory accepts one item per line and submits to the existing add_keys endpoint.
- design-reference.png: visual reference image used for the storefront direction.

Important:
1. Replace the existing index.html and admin.html in the GitHub Pages repository with these files.
2. Do not upload the reference PNG as a website asset unless you want it visible in the repository.
3. The top-up request uses the existing kds-api request_topup action. It sends the chosen method and amount to the configured admin Telegram account, then opens the supplied support group invite link.
4. The inventory editor uses the existing kds-admin add_keys action and stores each non-empty line as one stock item for the selected plan.
5. The package has not been published to GitHub Pages or deployed to Supabase. Test inside Telegram after replacing the files.
