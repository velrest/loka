# Tasks
Move the finished tasks to Done

## Quality checks
- Any funcitonality which is missing tests
- Code quality check
- Any templates that could be simplified
- Any code that could be simplified

## Next Feature

**Checkout, Payment & Studio Order Management** — two plans ready to execute in order:

1. `docs/superpowers/plans/2026-05-12-checkout-and-payment.md`
2. `docs/superpowers/plans/2026-05-12-studio-order-management.md`

**Plan 1 tasks (checkout & payment):**
- Task 1: Add missing domain functions (`get_cart_by_id`, `get_user_by_id`, `mark_order_paid`, `fulfil_order`, `cancel_order`) + bypass policies on Cart and Order for webhook use
- Task 2: Add `stripe_session_id` to `Order`, add `get_by_stripe_session` read action, expose in `Commerce` domain, generate migration
- Task 3: Add `stripity_stripe ~> 3.0` dependency + Stripe config (key from `STRIPE_SECRET_KEY` env, webhook secret from `STRIPE_WEBHOOK_SECRET` env)
- Task 4: Add `CacheBodyReader` plug so raw body is cached before `Plug.Parsers` consumes it — required for Stripe webhook signature verification
- Task 5: `StripeWebhookController` — handles `checkout.session.completed`: idempotency check via `Commerce.get_by_stripe_session`, creates order via `Commerce.place_order`, calls `Commerce.mark_order_paid!`, decrements stock via `Inventory.get_stock` + `Inventory.update_stock`, destroys cart via `Commerce.destroy_cart!`
- Task 6: `CheckoutLive` at `/shop/checkout` — groups cart by `stock_id` (no quantity field; count rows), builds Stripe line items using `Money.to_integer_exp(price) |> elem(0)` for `unit_amount` (NOT `Money.to_integer`), creates Stripe Checkout Session with `payment_method_types: ["card", "twint"]`, redirects to Stripe hosted page
- Task 7: `OrderSuccessLive` at `/shop/order/success` — confirmation page after Stripe redirects back

**Plan 2 tasks (studio order management):**
- Task 1: `list_studio_orders` read action on `Order` — uses `exists(order_lines.stock, studio_id == ^arg(:studio_id))` filter, policy: `actor_attribute_equals(:has_studio?, true)`, expose as `Commerce.list_studio_orders/2`
- Task 2: `OrdersLive` at `/inventory/orders` — shows paid orders for the studio, "Als versandt markieren" button calls `Commerce.fulfil_order!`, "Stornieren" calls `Commerce.cancel_order!`
- Task 3: Add "Bestellungen" tab to inventory nav

**Key gotchas to remember:**
- Stripe webhook route must be outside the browser pipeline (no CSRF protection)
- `fulfil` is spelled without double-l (not `fulfill`) — existing action name
- `authorize?: false` is forbidden in LiveViews — use bypass policies instead
- TWINT only works in CHF, max CHF 5000, no manual capture

## TODO
- **Pre-launch refactor:** Switch anonymous cart from localStorage/JS-hook to server-side `CartPlug` + Phoenix session. Eliminates flash of empty cart on first render. `EnsureForSession` + `MergeFrom` logic stays; refactor `AddToCartComponent` (remove `ensure_cart` JS flow), update `CartLive`, add `CartPlug`, handle merge in auth controller. Do after Stripe checkout is working.
- Map still not zooming to user location in firefox and chrome after permission is granted, remove all the console.logs in the leaflet compoenent again
- At some point, we well need to add some logic so stock is reserved for a user for some time after adding it to cart and the display of remaining items need to take this into consideration.
- **Pre-launch:** Update sender email in `send_password_reset_email.ex`, `send_new_user_confirmation_email.ex`, `send_magic_link_email.ex` (currently `noreply@example.com`)

## Done
- Map zooms to user location when permission granted (geolocation → `flyTo` zoom 11); stock list only filters to visible bounds at zoom ≥ 10 so zooming out still shows all studios
- Moved all LiveComponents into `./lib/loka_web/live/components` (`add_to_cart_component.ex`, `studio_map_component.ex`, `address_input_component.ex`)
- Removed redundant `handle_params` assigning `current_path` in views covered by `AssignCurrentPath` hook
- Policy sanity check: fixed Studio create policy — `forbid_if actor_attribute_equals(:has_studio?, true)` enforces one studio per user; added DB-level `unique_owner` identity
- Fixed `cart_live.ex` — replaced `Ash.destroy!` + `authorize?: false` with `Commerce.remove_from_cart!`
- Added tests for `cart_live.ex` (11 tests covering anonymous and authenticated flows)
- Checked for TODOs in code (only pre-launch email config remains)
- Squashed 20 incremental migrations into single `init` migration
